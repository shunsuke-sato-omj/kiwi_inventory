import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/lot.dart';

/// 収穫（自社栽培）・仕入れ（select提携先）の記録をSupabaseに保存するリポジトリ。
///
/// FR-004/FR-005/FR-006: 収穫・仕入れの記録ごとに1件の在庫ロットを作成し、
/// 初期状態は「冷蔵保管」とする（`lots.status`のDBデフォルトに委ねる）。
class HarvestRepository {
  HarvestRepository(this._client);

  final SupabaseClient _client;
  final Random _random = Random();

  static const int _maxLotCodeRetries = 5;

  /// Postgresの一意制約違反（unique_violation）のSQLSTATEコード。
  static const String _uniqueViolationCode = '23505';

  Future<void> recordHarvest({
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
    await _insertLotWithRetry({
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
    required String supplierId,
    required DateTime purchasedAt,
    double? weightKg,
    int? quantityCount,
    SizeGrade? sizeGrade,
    int? containerCount,
    String? storageLocationId,
  }) async {
    final String? userId = _client.auth.currentUser?.id;
    await _insertLotWithRetry({
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

  /// [values]に`lot_code`を付けてINSERTする。ロットコードの一意制約違反
  /// （まれな採番衝突）が起きた場合は、新しいコードを振り直して再試行する。
  Future<void> _insertLotWithRetry(Map<String, dynamic> values) async {
    for (var attempt = 0; attempt < _maxLotCodeRetries; attempt++) {
      try {
        await _client.from('lots').insert({
          ...values,
          'lot_code': _generateLotCode(),
        });
        return;
      } on PostgrestException catch (e) {
        final bool isLastAttempt = attempt == _maxLotCodeRetries - 1;
        if (e.code != _uniqueViolationCode || isLastAttempt) rethrow;
        // 一意制約違反（ロットコードの偶発的な衝突）のみ、コードを振り直して再試行する。
      }
    }
  }

  /// 「L-2609-123456」のような、日付＋ランダム値のロットコードを発行する。
  /// タイムスタンプの下数桁だけに頼ると短時間の連続入力で衝突しうるため、
  /// 十分な範囲の乱数を使い、それでも衝突した場合は[_insertLotWithRetry]が
  /// 振り直して再試行する（Principle V: 過剰な連番管理基盤は持たない）。
  String _generateLotCode() {
    final now = DateTime.now();
    final yy = (now.year % 100).toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final suffix = (_random.nextInt(900000) + 100000).toString();
    return 'L-$yy$mm-$suffix';
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
