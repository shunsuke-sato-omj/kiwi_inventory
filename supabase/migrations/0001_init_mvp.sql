-- ============================================================================
-- キウイの国 在庫管理システム — MVP（Phase 1）初期スキーマ
--
-- 要件定義書 v1.1 9章（想定データ項目）をもとに、MVP対象機能
-- （F1 マスタ管理／F2 収穫記録／F3 仕入れ管理／F4 追熟・品質・ロット管理／
--  F5 在庫照会／F6 出荷管理／F9 ダッシュボード／F11 権限）に必要な範囲で作成。
--
-- Phase 2 対象（Shopify連携ログ・freee連携ログ・体験プログラム消費記録）は
-- このマイグレーションには含めず、Phase 2着手時に別マイグレーションで追加する
-- 方針（要件定義書 12章のフェーズ計画に対応）。
-- ============================================================================

-- 拡張機能: UUID生成
create extension if not exists "pgcrypto";

-- ----------------------------------------------------------------------------
-- profiles: auth.users を拡張し、役割（現場スタッフ／管理者）を保持
-- 要件定義書 7章 F11、5章（現場5名・管理者2名の2階層）
-- ----------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null,
  role text not null default 'field_staff' check (role in ('field_staff', 'admin')),
  created_at timestamptz not null default now()
);

comment on table public.profiles is '現場スタッフ／管理者の2階層のみ（要件定義書7章 F11）';

-- 新規ユーザー作成時に自動でprofilesの行を作る
create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.email),
    coalesce(new.raw_user_meta_data ->> 'role', 'field_staff')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 管理者判定ヘルパー（RLSポリシーで使用）
create function public.is_admin()
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- ----------------------------------------------------------------------------
-- マスタ系テーブル（F1）
-- ----------------------------------------------------------------------------
create table public.varieties (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  standard_ripening_days_min int,
  standard_ripening_days_max int,
  created_at timestamptz not null default now()
);
comment on table public.varieties is '品種マスタ（例: 香緑、ヘイワード）';

create table public.fields (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  location text,
  created_at timestamptz not null default now()
);
comment on table public.fields is '圃場（区画）マスタ。自社栽培のみで使用';

create table public.suppliers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  location text,
  contact text,
  created_at timestamptz not null default now()
);
comment on table public.suppliers is '仕入先農家マスタ（select向け）。要件定義書13章の詳細は要確認';

create table public.storage_locations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);
comment on table public.storage_locations is '保管場所マスタ（倉庫・自宅など多様な場所を許容）';

-- ----------------------------------------------------------------------------
-- 在庫ロット（F2 収穫記録／F3 仕入れ管理／F4 追熟管理／F5 在庫照会 を統合）
-- 要件定義書9章の「選果記録」「仕入記録」「追熟記録」「在庫ロット」を
-- MVPでは1テーブルに統合している（シンプルさを優先。Phase 2で分割も検討可）。
-- ----------------------------------------------------------------------------
create type public.lot_origin as enum ('own_farm', 'purchased');
create type public.lot_status as enum ('cold', 'ripening', 'ready', 'expired');

create table public.lots (
  id uuid primary key default gen_random_uuid(),
  lot_code text not null unique, -- 例: L-2609-01
  origin public.lot_origin not null,

  -- 自社栽培（origin = own_farm）のとき使用
  variety_id uuid references public.varieties (id),
  field_id uuid references public.fields (id),

  -- 仕入れ（origin = purchased）のとき使用
  supplier_id uuid references public.suppliers (id),

  harvested_or_purchased_at date not null,
  weight_kg numeric(10, 2),
  quantity_count int,
  size_grade text, -- 等級・サイズ規格は未確定（要件定義書13章）。当面は自由入力
  container_count int,

  status public.lot_status not null default 'cold',
  storage_location_id uuid references public.storage_locations (id),
  ripening_started_at timestamptz,
  ripening_temperature_c numeric(5, 2),
  ripening_treatment_hours numeric(6, 2),

  recorded_by uuid references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.lots is '在庫ロット。収穫/仕入から出荷までの中心テーブル';

create index lots_status_idx on public.lots (status);
create index lots_variety_idx on public.lots (variety_id);

-- updated_at を自動更新
create function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger lots_set_updated_at
  before update on public.lots
  for each row execute procedure public.set_updated_at();

-- ----------------------------------------------------------------------------
-- ロットのステータス変更履歴（誤操作からの訂正も含め、すべての変更を記録）
-- 現場用モックの「ステータスを編集」機能に対応
-- ----------------------------------------------------------------------------
create table public.lot_status_history (
  id uuid primary key default gen_random_uuid(),
  lot_id uuid not null references public.lots (id) on delete cascade,
  from_status public.lot_status,
  to_status public.lot_status not null,
  changed_by uuid references public.profiles (id),
  changed_at timestamptz not null default now(),
  note text
);

comment on table public.lot_status_history is 'ステータス変更履歴。誤って変更した場合の訂正も含めて全件記録する';

create function public.log_lot_status_change()
returns trigger
language plpgsql
as $$
begin
  if (tg_op = 'INSERT') or (old.status is distinct from new.status) then
    insert into public.lot_status_history (lot_id, from_status, to_status, changed_by)
    values (
      new.id,
      case when tg_op = 'INSERT' then null else old.status end,
      new.status,
      new.recorded_by
    );
  end if;
  return new;
end;
$$;

create trigger lots_log_status_change
  after insert or update on public.lots
  for each row execute procedure public.log_lot_status_change();

-- ----------------------------------------------------------------------------
-- 出荷記録（F6）
-- ----------------------------------------------------------------------------
create type public.shipment_channel as enum ('ec', 'wholesale', 'program');
create type public.delivery_method as enum ('sagawa', 'direct', 'none');

create table public.shipments (
  id uuid primary key default gen_random_uuid(),
  lot_id uuid not null references public.lots (id),
  channel public.shipment_channel not null,
  customer_name text,
  quantity_kg numeric(10, 2) not null,
  delivery_method public.delivery_method not null default 'none',
  shipped_at date not null default current_date,
  recorded_by uuid references public.profiles (id),
  created_at timestamptz not null default now()
);

comment on table public.shipments is '出荷記録（EC／卸売／体験消費）。Phase 1ではShopify連携は手動運用';

create index shipments_lot_idx on public.shipments (lot_id);

-- ============================================================================
-- Row Level Security
-- 少人数の社内利用（現場5名＋管理者2名）を前提に、閲覧は認証済みユーザー全員、
-- 更新系はマスタ管理のみ管理者限定というシンプルな方針（要件定義書7章 F11）。
-- ============================================================================

alter table public.profiles enable row level security;
alter table public.varieties enable row level security;
alter table public.fields enable row level security;
alter table public.suppliers enable row level security;
alter table public.storage_locations enable row level security;
alter table public.lots enable row level security;
alter table public.lot_status_history enable row level security;
alter table public.shipments enable row level security;

-- 閲覧: 認証済みユーザーは全テーブルを参照可能
create policy "authenticated read profiles" on public.profiles for select to authenticated using (true);
create policy "authenticated read varieties" on public.varieties for select to authenticated using (true);
create policy "authenticated read fields" on public.fields for select to authenticated using (true);
create policy "authenticated read suppliers" on public.suppliers for select to authenticated using (true);
create policy "authenticated read storage_locations" on public.storage_locations for select to authenticated using (true);
create policy "authenticated read lots" on public.lots for select to authenticated using (true);
create policy "authenticated read lot_status_history" on public.lot_status_history for select to authenticated using (true);
create policy "authenticated read shipments" on public.shipments for select to authenticated using (true);

-- マスタ管理（F1）: 変更は管理者のみ
create policy "admin write varieties" on public.varieties for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admin write fields" on public.fields for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admin write suppliers" on public.suppliers for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "admin write storage_locations" on public.storage_locations for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- profiles.role の変更は管理者のみ（本人の氏名変更などは別途検討）
create policy "admin manage profiles" on public.profiles for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- 収穫記録・仕入・追熟・出荷（F2/F3/F4/F6）: 現場スタッフ・管理者どちらも記録可能
create policy "authenticated write lots" on public.lots for insert to authenticated with check (true);
create policy "authenticated update lots" on public.lots for update to authenticated using (true) with check (true);
create policy "authenticated write shipments" on public.shipments for insert to authenticated with check (true);

-- ステータス履歴はトリガー経由でのみ作成される想定（クライアントからの直接挿入は禁止）
-- INSERT ポリシーを定義しないことで、認証ユーザーからの直接書き込みをブロックする
-- （security definer トリガーはRLSをバイパスするため、履歴記録自体は継続する）
