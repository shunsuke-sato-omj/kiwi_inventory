-- ============================================================================
-- 仕入先マスタに取引開始日を追加
--
-- 001-inventory-mvp の /speckit-clarify（2026-09-02）で、仕入先マスタの
-- 最低限必要な項目として「仕入先名・連絡先・住所・取引開始日」が確定した。
-- 0001_init_mvp.sql の suppliers テーブルには住所相当（location）と連絡先
-- （contact）はあるが取引開始日が無いため、本マイグレーションで追加する。
-- ============================================================================

alter table public.suppliers
  add column if not exists contract_started_at date;

comment on column public.suppliers.contract_started_at is
  '取引開始日（/speckit-clarify 2026-09-02 で確定した仕入先マスタの必須項目）';
