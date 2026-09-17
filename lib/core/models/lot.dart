import 'package:equatable/equatable.dart';

import '../theme/app_theme.dart';

/// 収穫（自社栽培）か仕入れ（select提携先）かの区分。
enum LotOrigin { ownFarm, purchased }

extension LotOriginX on LotOrigin {
  static LotOrigin fromDb(String value) => switch (value) {
    'purchased' => LotOrigin.purchased,
    _ => LotOrigin.ownFarm,
  };

  String get dbValue => switch (this) {
    LotOrigin.ownFarm => 'own_farm',
    LotOrigin.purchased => 'purchased',
  };

  String get label => switch (this) {
    LotOrigin.ownFarm => '自社収穫',
    LotOrigin.purchased => '仕入れ',
  };
}

/// サイズ・等級区分。
///
/// 社内共通の等級・サイズ基準が未確定なため、/speckit-clarify（2026-09-02）で
/// S/M/L/2Lの4区分を暫定採用することを確定した（FR-016）。社内基準が確定した
/// 場合はこのenumと `size_grade` の選択肢を見直す。
enum SizeGrade { s, m, l, twoL }

extension SizeGradeX on SizeGrade {
  static SizeGrade? fromDb(String? value) => switch (value) {
    'S' => SizeGrade.s,
    'M' => SizeGrade.m,
    'L' => SizeGrade.l,
    '2L' => SizeGrade.twoL,
    _ => null,
  };

  String get dbValue => switch (this) {
    SizeGrade.s => 'S',
    SizeGrade.m => 'M',
    SizeGrade.l => 'L',
    SizeGrade.twoL => '2L',
  };

  String get label => dbValue;
}

/// 在庫ロット。収穫または仕入れの単位（在庫管理の中心エンティティ）。
class Lot extends Equatable {
  const Lot({
    required this.id,
    required this.lotCode,
    required this.origin,
    required this.status,
    required this.harvestedOrPurchasedAt,
    this.varietyId,
    this.varietyName,
    this.fieldId,
    this.supplierId,
    this.weightKg,
    this.quantityCount,
    this.sizeGrade,
    this.containerCount,
    this.storageLocationId,
    this.ripeningStartedAt,
  });

  factory Lot.fromRow(Map<String, dynamic> row) => Lot(
    id: row['id'] as String,
    lotCode: row['lot_code'] as String,
    origin: LotOriginX.fromDb(row['origin'] as String),
    status: LotStatusX.fromDb(row['status'] as String),
    harvestedOrPurchasedAt: DateTime.parse(
      row['harvested_or_purchased_at'] as String,
    ),
    varietyId: row['variety_id'] as String?,
    varietyName:
        (row['varieties'] as Map<String, dynamic>?)?['name'] as String?,
    fieldId: row['field_id'] as String?,
    supplierId: row['supplier_id'] as String?,
    weightKg: (row['weight_kg'] as num?)?.toDouble(),
    quantityCount: row['quantity_count'] as int?,
    sizeGrade: SizeGradeX.fromDb(row['size_grade'] as String?),
    containerCount: row['container_count'] as int?,
    storageLocationId: row['storage_location_id'] as String?,
    ripeningStartedAt: row['ripening_started_at'] == null
        ? null
        : DateTime.parse(row['ripening_started_at'] as String),
  );

  final String id;
  final String lotCode;
  final LotOrigin origin;
  final LotStatus status;
  final DateTime harvestedOrPurchasedAt;
  final String? varietyId;
  final String? varietyName;
  final String? fieldId;
  final String? supplierId;
  final double? weightKg;
  final int? quantityCount;
  final SizeGrade? sizeGrade;
  final int? containerCount;
  final String? storageLocationId;
  final DateTime? ripeningStartedAt;

  /// 出荷可否の判断・ダッシュボード集計に使う数量。重量を優先し、なければ個数を使う。
  num get primaryQuantity => weightKg ?? quantityCount ?? 0;

  @override
  List<Object?> get props => [
    id,
    lotCode,
    origin,
    status,
    harvestedOrPurchasedAt,
    varietyId,
    varietyName,
    fieldId,
    supplierId,
    weightKg,
    quantityCount,
    sizeGrade,
    containerCount,
    storageLocationId,
    ripeningStartedAt,
  ];
}

/// ロットのステータス変更履歴の1件（FR-009）。
class LotStatusHistoryEntry extends Equatable {
  const LotStatusHistoryEntry({
    required this.id,
    required this.lotId,
    required this.toStatus,
    required this.changedAt,
    this.fromStatus,
  });

  factory LotStatusHistoryEntry.fromRow(Map<String, dynamic> row) =>
      LotStatusHistoryEntry(
        id: row['id'] as String,
        lotId: row['lot_id'] as String,
        fromStatus: row['from_status'] == null
            ? null
            : LotStatusX.fromDb(row['from_status'] as String),
        toStatus: LotStatusX.fromDb(row['to_status'] as String),
        changedAt: DateTime.parse(row['changed_at'] as String),
      );

  final String id;
  final String lotId;
  final LotStatus? fromStatus;
  final LotStatus toStatus;
  final DateTime changedAt;

  @override
  List<Object?> get props => [id, lotId, fromStatus, toStatus, changedAt];
}
