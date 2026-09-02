/// 出荷数量が対象ロットの残り在庫数量を超えていないかを検証する（FR-017）。
///
/// `/speckit-clarify`（2026-09-02）で「保存前にブロックする」ことを確定した。
/// 超過している場合はエラーメッセージを返し、それ以外（ちょうど・下回る）は
/// `null` を返す純粋関数とすることで、Supabaseなしでもユニットテストできる
/// ようにする（Principle II: 非自明なビジネスロジックのテスト必須）。
String? validateShipmentQuantity({
  required num requested,
  required num remaining,
}) {
  if (requested <= 0) {
    return '出荷数量は1以上を入力してください。';
  }
  if (requested > remaining) {
    return '出荷数量が残り在庫（$remaining）を超えています。数量を見直してください。';
  }
  return null;
}
