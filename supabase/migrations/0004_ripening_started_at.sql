-- ============================================================================
-- コードレビューで見つかった修正（2026-09-10）
--
-- update_lot_status が status カラムしか更新していなかったため、
-- lots.ripening_started_at が常にNULLのままだった。
-- lotsNearingRipeness()（FR-013「追熟完了が近いロット」）は
-- ripening_started_at が null のロットを必ず除外する実装のため、
-- ステータスを「追熟中」に変更しても ripening_started_at が記録されず、
-- ホーム画面の「追熟完了が近いロット」が常に空になる不具合があった。
--
-- 「追熟中」へ遷移するたびに ripening_started_at を現在時刻でセットし直す。
-- （一度「冷蔵保管」等に戻して再度「追熟中」にした場合も、そこから
--   改めて追熟日数のカウントを始める想定。それ以外への遷移では
--   既存の値をそのまま保持する。）
-- ============================================================================
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
  set
    status = p_new_status,
    ripening_started_at = case
      when p_new_status = 'ripening' then now()
      else ripening_started_at
    end
  where id = p_lot_id;

  if not found then
    raise exception 'ロットが見つかりませんでした。';
  end if;
end;
$$;
