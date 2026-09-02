import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/lot.dart';

/// 収穫（自社栽培）・仕入れ（select提携先）の記録をSupabaseに保存するリポジトリ。
///
/// FR-004/FR-005/FR-006: 収穫・仕入れの記録ごとに1件の在庫ロットを作成し、
/// 初期状態は「冷蔵保管」とする（`lots.status`のDBデフォルトに委ねる）。
class HarvestRepository {
  HarvestRepository(this._client);

  final SupabaseClient _client;

  Future<void> recordHarvest({
    required String lotCode,
    required String varietyId,
    required String fieldId,
    required DateTime harvestedAt,
    double? weightKg,
    int? quantityCount,
    SizeGrade? sizeGrade,
    int? containerCount,
    String? storageLocationId,
  }) async {
    final String? userId = _client.auth.currentUser?.id;
    await _client.from('lots').insert({
      'lot_code': lotCode,
      'origin': LotOrigin.ownFarm.dbValue,
      'variety_id': varietyId,
      'field_id': fieldId,
      'harvested_or_purchased_at': _formatDate(harvestedAt),
      'weight_kg': weightKg,
      'quantity_count': quantityCount,
      'size_grade': sizeGrade?.dbValue,
      'container_count': containerCount,
      'storage_location_id': storageLocationId,
      'recorded_by': userId,
    });
  }

  Future<void> recordPurchase({
    required String lotCode,
    required String supplierId,
    required DateTime purchasedAt,
    double? weightKg,
    int? quantityCount,
    SizeGrade? sizeGrade,
    int? containerCount,
    String? storageLocationId,
  }) async {
    final String? userId = _client.auth.currentUser?.id;
    await _client.from('lots').insert({
      'lot_code': lotCode,
      'origin': LotOrigin.purchased.dbValue,
      'supplier_id': supplierId,
      'harvested_or_purchased_at': _formatDate(purchasedAt),
      'weight_kg': weightKg,
      'quantity_count': quantityCount,
      'size_grade': sizeGrade?.dbValue,
      'container_count': containerCount,
      'storage_location_id': storageLocationId,
      'recorded_by': userId,
    });
  }

  /// 「L-2609-01」のような、日付＋連番のロットコードを発行する。
  /// MVP規模（7名・小規模在庫）では厳密な連番管理は不要なため、
  /// タイムスタンプを使った衝突しにくい採番にとどめる（Principle V）。
  String generateLotCode() {
    final now = DateTime.now();
    final yy = (now.year % 100).toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final suffix = now.millisecondsSinceEpoch.remainder(100000).toString();
    return 'L-$yy$mm-$suffix';
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
