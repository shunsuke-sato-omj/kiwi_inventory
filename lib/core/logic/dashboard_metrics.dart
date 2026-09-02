import '../models/lot.dart';
import '../models/master_data.dart';
import '../theme/app_theme.dart';

/// 「追熟完了が近い」と判定する残日数の暫定しきい値（FR-013）。
///
/// 要件定義書・ヒアリングで具体的な日数の合意はまだ無いため、実装上の
/// 暫定値として置く。ReFruitsとの確認が取れ次第、値を見直すこと（Principle IV）。
const int kNearingRipenessWithinDays = 2;

/// 「在庫が少ない」と判定する在庫量(kg)の暫定しきい値（FR-014）。
/// 上記と同様、ReFruitsとの正式合意までの暫定値。
const num kLowStockThresholdKg = 10;

/// 追熟完了目安日（品種の標準追熟日数 + 追熟開始日）までの残日数が
/// [withinDays] 以下（まだ過ぎていないもの）のロットを返す（FR-013）。
List<Lot> lotsNearingRipeness(
  List<Lot> lots,
  List<Variety> varieties, {
  int withinDays = kNearingRipenessWithinDays,
  DateTime? now,
}) {
  final nowDate = now ?? DateTime.now();
  final varietyById = {for (final v in varieties) v.id: v};

  return lots.where((lot) {
    if (lot.status != LotStatus.ripening) return false;
    final ripeningStartedAt = lot.ripeningStartedAt;
    if (ripeningStartedAt == null) return false;

    final variety = lot.varietyId == null ? null : varietyById[lot.varietyId];
    final int? standardDays =
        variety?.standardRipeningDaysMax ?? variety?.standardRipeningDaysMin;
    if (standardDays == null) return false;

    final expectedCompletion = ripeningStartedAt.add(
      Duration(days: standardDays),
    );
    final daysRemaining = expectedCompletion.difference(nowDate).inDays;
    return daysRemaining >= 0 && daysRemaining <= withinDays;
  }).toList();
}

/// 品種ごとの重量（kg）合計（期限切れロットは除く）が [threshold] を
/// 下回る品種を返す（FR-014）。
///
/// 重要な既知の制限: `threshold` はkg単位のしきい値だが、ロットは重量(kg)と
/// 個数のどちらか一方で記録される（FR-016）。個数のみで記録されたロットは
/// このkg基準の判定には含めない（重量と個数を単純合算すると単位が異なる値を
/// 混ぜることになり、誤った低在庫アラートを出しかねないため）。
/// 「個数だけで記録された在庫をどう低在庫判定に含めるか」は要件定義書側で
/// 決まっていない事項であり、ReFruitsとの確認が必要（Principle IV: 推測しない）。
/// 確認が取れるまでは、個数のみのロットは本判定の対象外という扱いになる。
List<Variety> lowStockVarieties(
  List<Lot> lots,
  List<Variety> varieties, {
  num threshold = kLowStockThresholdKg,
}) {
  final totals = <String, num>{};
  for (final lot in lots) {
    final varietyId = lot.varietyId;
    if (varietyId == null || lot.status == LotStatus.expired) continue;
    if (lot.weightKg == null) continue; // 個数のみのロットはkg基準の対象外
    totals[varietyId] = (totals[varietyId] ?? 0) + lot.weightKg!;
  }
  return varieties.where((v) => (totals[v.id] ?? 0) < threshold).toList();
}
