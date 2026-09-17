import 'package:equatable/equatable.dart';

/// 品種マスタ（例: 香緑、ヘイワード）。
/// 標準追熟日数の目安を持つ（ダッシュボードの「追熟完了が近いロット」判定に使用）。
class Variety extends Equatable {
  const Variety({
    required this.id,
    required this.name,
    this.standardRipeningDaysMin,
    this.standardRipeningDaysMax,
  });

  factory Variety.fromRow(Map<String, dynamic> row) => Variety(
    id: row['id'] as String,
    name: row['name'] as String,
    standardRipeningDaysMin: row['standard_ripening_days_min'] as int?,
    standardRipeningDaysMax: row['standard_ripening_days_max'] as int?,
  );

  final String id;
  final String name;
  final int? standardRipeningDaysMin;
  final int? standardRipeningDaysMax;

  @override
  List<Object?> get props => [
    id,
    name,
    standardRipeningDaysMin,
    standardRipeningDaysMax,
  ];
}

/// 圃場（区画）マスタ。自社栽培の区画。
class FarmField extends Equatable {
  const FarmField({required this.id, required this.name, this.location});

  factory FarmField.fromRow(Map<String, dynamic> row) => FarmField(
    id: row['id'] as String,
    name: row['name'] as String,
    location: row['location'] as String?,
  );

  final String id;
  final String name;
  final String? location;

  @override
  List<Object?> get props => [id, name, location];
}

/// 仕入先（select提携先の農家）マスタ。
/// 仕入先名・連絡先・住所・取引開始日を持つ（/speckit-clarify 2026-09-02 で確定）。
class Supplier extends Equatable {
  const Supplier({
    required this.id,
    required this.name,
    this.location,
    this.contact,
    this.contractStartedAt,
  });

  factory Supplier.fromRow(Map<String, dynamic> row) => Supplier(
    id: row['id'] as String,
    name: row['name'] as String,
    location: row['location'] as String?,
    contact: row['contact'] as String?,
    contractStartedAt: row['contract_started_at'] == null
        ? null
        : DateTime.parse(row['contract_started_at'] as String),
  );

  final String id;
  final String name;
  final String? location;
  final String? contact;
  final DateTime? contractStartedAt;

  @override
  List<Object?> get props => [id, name, location, contact, contractStartedAt];
}

/// 保管場所マスタ（倉庫、自宅保管など多様な場所を許容）。
class StorageLocation extends Equatable {
  const StorageLocation({required this.id, required this.name});

  factory StorageLocation.fromRow(Map<String, dynamic> row) =>
      StorageLocation(id: row['id'] as String, name: row['name'] as String);

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
