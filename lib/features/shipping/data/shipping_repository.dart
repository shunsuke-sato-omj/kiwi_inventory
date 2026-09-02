import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/lot.dart';
import '../../../core/models/shipment.dart';
import '../../../core/validation/shipment_validation.dart';

/// 出荷可能な在庫ロット（FR-011）と、その残り在庫数量の算出・出荷記録の保存を
/// 担うリポジトリ。保存前に必ず [validateShipmentQuantity] でチェックする（FR-017）。
class ShippingRepository {
  ShippingRepository(this._client);

  final SupabaseClient _client;

  /// 出荷先選択用に、出荷可能（冷蔵保管以外も含め全ロット）を返す。
  /// MVPでは状態による絞り込みは行わず、現場の判断に委ねる。
  Future<List<Lot>> fetchShippableLots() async {
    final rows = await _client
        .from('lots')
        .select('*, varieties(name)')
        .order('harvested_or_purchased_at', ascending: false);
    return rows.map(Lot.fromRow).toList();
  }

  /// 対象ロットの残り在庫数量（ロットの重量 − 既存出荷分の合計）。
  Future<num> fetchRemainingQuantity(String lotId) async {
    final lotRow = await _client
        .from('lots')
        .select('weight_kg, quantity_count')
        .eq('id', lotId)
        .single();
    final num total =
        (lotRow['weight_kg'] as num?) ?? (lotRow['quantity_count'] as num?) ?? 0;

    final shipmentRows = await _client
        .from('shipments')
        .select('quantity_kg')
        .eq('lot_id', lotId);
    final num shipped = shipmentRows.fold<num>(
      0,
      (sum, row) => sum + ((row['quantity_kg'] as num?) ?? 0),
    );

    final num remaining = total - shipped;
    return remaining < 0 ? 0 : remaining;
  }

  /// 出荷記録を保存する。保存前に残り在庫を超えていないかを検証し、
  /// 超えている場合は [ShipmentQuantityExceededException] を投げて保存しない（FR-017）。
  Future<void> createShipment({
    required String lotId,
    required ShipmentChannel channel,
    required num quantityKg,
    required DeliveryMethod deliveryMethod,
    required DateTime shippedAt,
    String? customerName,
  }) async {
    final num remaining = await fetchRemainingQuantity(lotId);
    final String? validationError = validateShipmentQuantity(
      requested: quantityKg,
      remaining: remaining,
    );
    if (validationError != null) {
      throw ShipmentQuantityExceededException(validationError);
    }

    final String? userId = _client.auth.currentUser?.id;
    await _client.from('shipments').insert({
      'lot_id': lotId,
      'channel': channel.dbValue,
      'quantity_kg': quantityKg,
      'delivery_method': channel.requiresDeliveryMethod
          ? deliveryMethod.dbValue
          : DeliveryMethod.none.dbValue,
      'shipped_at': _formatDate(shippedAt),
      'customer_name': customerName,
      'recorded_by': userId,
    });
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

/// FR-017: 出荷数量が残り在庫を超える場合に投げる例外。
/// UI側でこの例外を捕捉し、[message] をそのままインライン表示する。
class ShipmentQuantityExceededException implements Exception {
  ShipmentQuantityExceededException(this.message);

  final String message;

  @override
  String toString() => message;
}
