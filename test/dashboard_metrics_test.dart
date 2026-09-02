import 'package:flutter_test/flutter_test.dart';
import 'package:kiwi_inventory/core/logic/dashboard_metrics.dart';
import 'package:kiwi_inventory/core/models/lot.dart';
import 'package:kiwi_inventory/core/models/master_data.dart';
import 'package:kiwi_inventory/core/theme/app_theme.dart';

Lot _lot({
  required String id,
  LotStatus status = LotStatus.cold,
  String? varietyId,
  double? weightKg,
  int? quantityCount,
  DateTime? ripeningStartedAt,
}) {
  return Lot(
    id: id,
    lotCode: 'L-$id',
    origin: LotOrigin.ownFarm,
    status: status,
    harvestedOrPurchasedAt: DateTime(2026, 8, 1),
    varietyId: varietyId,
    weightKg: weightKg,
    quantityCount: quantityCount,
    ripeningStartedAt: ripeningStartedAt,
  );
}

void main() {
  final now = DateTime(2026, 9, 2);
  const variety = Variety(
    id: 'v1',
    name: '香緑',
    standardRipeningDaysMin: 7,
    standardRipeningDaysMax: 10,
  );

  group('lotsNearingRipeness', () {
    test('追熟完了目安まで残り2日以内のロットを含む', () {
      final lot = _lot(
        id: '1',
        status: LotStatus.ripening,
        varietyId: 'v1',
        // 標準10日 → 8/1 + 10日 = 8/11 (すでに過ぎている場合は対象外なので、
        // now を基準に「あと1日」になるよう調整する)
        ripeningStartedAt: now.subtract(const Duration(days: 9)),
      );
      final result = lotsNearingRipeness([lot], [variety], now: now);
      expect(result, contains(lot));
    });

    test('追熟中でないロットは含まない', () {
      final lot = _lot(
        id: '2',
        status: LotStatus.cold,
        varietyId: 'v1',
        ripeningStartedAt: now.subtract(const Duration(days: 9)),
      );
      expect(lotsNearingRipeness([lot], [variety], now: now), isEmpty);
    });

    test('まだ十分日数が残っているロットは含まない', () {
      final lot = _lot(
        id: '3',
        status: LotStatus.ripening,
        varietyId: 'v1',
        ripeningStartedAt: now, // 標準10日なのでまだ10日残っている
      );
      expect(lotsNearingRipeness([lot], [variety], now: now), isEmpty);
    });

    test('すでに目安日数を過ぎたロットは含まない（期限切れとして別途扱う）', () {
      final lot = _lot(
        id: '4',
        status: LotStatus.ripening,
        varietyId: 'v1',
        ripeningStartedAt: now.subtract(const Duration(days: 20)),
      );
      expect(lotsNearingRipeness([lot], [variety], now: now), isEmpty);
    });
  });

  group('lowStockVarieties', () {
    test('在庫合計がしきい値未満の品種を含む', () {
      final lots = [_lot(id: '1', varietyId: 'v1', weightKg: 3)];
      final result = lowStockVarieties(lots, [variety], threshold: 10);
      expect(result, contains(variety));
    });

    test('在庫合計がしきい値以上の品種は含まない', () {
      final lots = [_lot(id: '1', varietyId: 'v1', weightKg: 20)];
      final result = lowStockVarieties(lots, [variety], threshold: 10);
      expect(result, isEmpty);
    });

    test('期限切れロットは在庫合計に含めない', () {
      final lots = [
        _lot(id: '1', varietyId: 'v1', weightKg: 20, status: LotStatus.expired),
      ];
      final result = lowStockVarieties(lots, [variety], threshold: 10);
      expect(result, contains(variety));
    });

    test('個数のみで記録されたロットはkg基準の合計に含めない（単位混在防止）', () {
      // 重量(kg)と個数は単位が異なるため単純合算しない。
      // 個数のみのロット（quantityCount=500）は無視され、
      // 重量記録が無い（＝合計0kg）ためしきい値未満と判定される。
      final lots = [_lot(id: '1', varietyId: 'v1', quantityCount: 500)];
      final result = lowStockVarieties(lots, [variety], threshold: 10);
      expect(result, contains(variety));
    });
  });
}
