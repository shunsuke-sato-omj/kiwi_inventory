-- ============================================================================
-- コードレビューで見つかった重大な修正（2026-09-02）
--
-- 1. log_lot_status_change トリガーに security definer が抜けていた。
--    lot_status_history にはRLSでauthenticatedへのINSERT許可が無いため、
--    このままでは収穫・仕入れ・ステータス変更のたびにトリガー自身のINSERTが
--    RLSに拒否され、トランザクション全体がロールバックする（＝実質すべての
--    書き込みが失敗する）致命的なバグだった。
--
-- 2. "authenticated update lots" ポリシーが using(true)/with check(true) で
--    全カラムを誰でも更新できてしまっていた（本来はステータスのみのはず）。
--    → ステータス変更は専用のRPC関数(update_lot_status)経由に限定し、
--      直接UPDATEのポリシーは撤去する。
--
-- 3. 出荷数量が残り在庫を超えていないかのチェック(FR-017)が、
--    「残数取得→検証→INSERT」という複数回のAPI呼び出しに分かれており、
--    DB側の裏付けが無いため同時出荷ですり抜けられる可能性があった。
--    → 行ロック(for update)を使った単一トランザクションのRPC関数
--      (create_shipment)に統合し、直接INSERTのポリシーは撤去する。
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. トリガー関数に security definer を付与
-- ----------------------------------------------------------------------------
create or replace function public.log_lot_status_change()
returns trigger
language plpgsql
security definer set search_path = public
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

-- ----------------------------------------------------------------------------
-- 2. ステータス変更を専用RPCに限定し、直接UPDATEポリシーを撤去
-- ----------------------------------------------------------------------------
drop policy if exists "authenticated update lots" on public.lots;

create or replace function public.update_lot_status(
  p_lot_id uuid,
  p_new_status public.lot_status
)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  update public.lots
  set status = p_new_status
  where id = p_lot_id;

  if not found then
    raise exception 'ロットが見つかりませんでした。';
  end if;
end;
$$;

revoke all on function public.update_lot_status(uuid, public.lot_status) from public;
grant execute on function public.update_lot_status(uuid, public.lot_status) to authenticated;

-- ----------------------------------------------------------------------------
-- 3. 出荷記録を「残数チェック＋INSERT」の単一トランザクションRPCに統合
--    (for updateでロットを行ロックし、同時出荷による超過を防ぐ)
-- ----------------------------------------------------------------------------
drop policy if exists "authenticated write shipments" on public.shipments;

create or replace function public.create_shipment(
  p_lot_id uuid,
  p_channel public.shipment_channel,
  p_quantity_kg numeric,
  p_delivery_method public.delivery_method,
  p_shipped_at date,
  p_customer_name text
)
returns public.shipments
language plpgsql
security definer set search_path = public
as $$
declare
  v_total numeric;
  v_shipped numeric;
  v_remaining numeric;
  v_row public.shipments;
begin
  select coalesce(weight_kg, quantity_count, 0) into v_total
  from public.lots
  where id = p_lot_id
  for update; -- 同一ロットへの同時出荷をここで直列化する

  if not found then
    raise exception 'ロットが見つかりませんでした。';
  end if;

  select coalesce(sum(quantity_kg), 0) into v_shipped
  from public.shipments
  where lot_id = p_lot_id;

  v_remaining := v_total - v_shipped;

  if p_quantity_kg <= 0 then
    raise exception '出荷数量は1以上を入力してください。';
  end if;

  if p_quantity_kg > v_remaining then
    raise exception '出荷数量が残り在庫（%）を超えています。数量を見直してください。', v_remaining;
  end if;

  insert into public.shipments (
    lot_id, channel, quantity_kg, delivery_method, shipped_at, customer_name, recorded_by
  )
  values (
    p_lot_id, p_channel, p_quantity_kg, p_delivery_method, p_shipped_at, p_customer_name, auth.uid()
  )
  returning * into v_row;

  return v_row;
end;
$$;

revoke all on function public.create_shipment(
  uuid, public.shipment_channel, numeric, public.delivery_method, date, text
) from public;
grant execute on function public.create_shipment(
  uuid, public.shipment_channel, numeric, public.delivery_method, date, text
) to authenticated;
