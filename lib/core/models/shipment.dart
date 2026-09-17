import 'package:equatable/equatable.dart';

/// 出荷先の種類（FR-011）。
enum ShipmentChannel { ec, wholesale, program }

extension ShipmentChannelX on ShipmentChannel {
  static ShipmentChannel fromDb(String value) => switch (value) {
    'wholesale' => ShipmentChannel.wholesale,
    'program' => ShipmentChannel.program,
    _ => ShipmentChannel.ec,
  };

  String get dbValue => switch (this) {
    ShipmentChannel.ec => 'ec',
    ShipmentChannel.wholesale => 'wholesale',
    ShipmentChannel.program => 'program',
  };

  String get label => switch (this) {
    ShipmentChannel.ec => 'EC',
    ShipmentChannel.wholesale => '卸売',
    ShipmentChannel.program => '体験プログラム',
  };

  /// 体験プログラムでは配送方法の入力を求めない（FR-012）。
  bool get requiresDeliveryMethod => this != ShipmentChannel.program;
}

/// 配送方法。
enum DeliveryMethod { sagawa, direct, none }

extension DeliveryMethodX on DeliveryMethod {
  static DeliveryMethod fromDb(String value) => switch (value) {
    'sagawa' => DeliveryMethod.sagawa,
    'direct' => DeliveryMethod.direct,
    _ => DeliveryMethod.none,
  };

  String get dbValue => switch (this) {
    DeliveryMethod.sagawa => 'sagawa',
    DeliveryMethod.direct => 'direct',
    DeliveryMethod.none => 'none',
  };

  String get label => switch (this) {
    DeliveryMethod.sagawa => '佐川急便',
    DeliveryMethod.direct => '直接手渡し',
    DeliveryMethod.none => 'なし',
  };
}

/// 出荷記録（FR-011）。
class Shipment extends Equatable {
  const Shipment({
    required this.id,
    required this.lotId,
    required this.channel,
    required this.quantityKg,
    required this.deliveryMethod,
    required this.shippedAt,
    this.customerName,
  });

  factory Shipment.fromRow(Map<String, dynamic> row) => Shipment(
    id: row['id'] as String,
    lotId: row['lot_id'] as String,
    channel: ShipmentChannelX.fromDb(row['channel'] as String),
    quantityKg: (row['quantity_kg'] as num).toDouble(),
    deliveryMethod: DeliveryMethodX.fromDb(row['delivery_method'] as String),
    shippedAt: DateTime.parse(row['shipped_at'] as String),
    customerName: row['customer_name'] as String?,
  );

  final String id;
  final String lotId;
  final ShipmentChannel channel;
  final double quantityKg;
  final DeliveryMethod deliveryMethod;
  final DateTime shippedAt;
  final String? customerName;

  @override
  List<Object?> get props => [
    id,
    lotId,
    channel,
    quantityKg,
    deliveryMethod,
    shippedAt,
    customerName,
  ];
}
