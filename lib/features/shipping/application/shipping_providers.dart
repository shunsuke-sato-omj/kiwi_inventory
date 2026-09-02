import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/lot.dart';
import '../../../core/models/shipment.dart';
import '../../auth/application/auth_providers.dart';
import '../data/shipping_repository.dart';

final Provider<ShippingRepository> shippingRepositoryProvider =
    Provider<ShippingRepository>(
      (ref) => ShippingRepository(ref.watch(supabaseClientProvider)),
    );

/// 出荷先選択用のロット一覧。
final FutureProvider<List<Lot>> shippableLotsProvider =
    FutureProvider<List<Lot>>(
      (ref) => ref.watch(shippingRepositoryProvider).fetchShippableLots(),
    );

/// 選択中ロットの残り在庫数量（FR-017のUI側事前表示に使う）。
final remainingQuantityProvider = FutureProvider.family<num, String>(
  (ref, lotId) =>
      ref.watch(shippingRepositoryProvider).fetchRemainingQuantity(lotId),
);

/// 出荷フォームの送信状態。
class ShipmentFormController extends StateNotifier<AsyncValue<void>> {
  ShipmentFormController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<bool> submit({
    required String lotId,
    required ShipmentChannel channel,
    required num quantityKg,
    required DeliveryMethod deliveryMethod,
    required DateTime shippedAt,
    String? customerName,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _ref
          .read(shippingRepositoryProvider)
          .createShipment(
            lotId: lotId,
            channel: channel,
            quantityKg: quantityKg,
            deliveryMethod: deliveryMethod,
            shippedAt: shippedAt,
            customerName: customerName,
          );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final StateNotifierProvider<ShipmentFormController, AsyncValue<void>>
shipmentFormControllerProvider =
    StateNotifierProvider<ShipmentFormController, AsyncValue<void>>(
      (ref) => ShipmentFormController(ref),
    );
