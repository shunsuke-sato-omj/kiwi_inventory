import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/lot.dart';
import '../../auth/application/auth_providers.dart';
import '../../master_data/application/master_data_providers.dart';
import '../data/harvest_repository.dart';

final Provider<HarvestRepository> harvestRepositoryProvider =
    Provider<HarvestRepository>(
      (ref) => HarvestRepository(ref.watch(supabaseClientProvider)),
    );

/// 収穫・仕入れフォームの送信状態（送信中/成功/エラー）。
/// 成功後は呼び出し側でフォームをリセットする（US2 Acceptance Scenario 3）。
class HarvestFormController extends StateNotifier<AsyncValue<void>> {
  HarvestFormController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<bool> submitHarvest({
    required String varietyId,
    required String fieldId,
    required DateTime harvestedAt,
    double? weightKg,
    int? quantityCount,
    SizeGrade? sizeGrade,
    int? containerCount,
    String? storageLocationId,
  }) => _submit(() {
    final repository = _ref.read(harvestRepositoryProvider);
    return repository.recordHarvest(
      varietyId: varietyId,
      fieldId: fieldId,
      harvestedAt: harvestedAt,
      weightKg: weightKg,
      quantityCount: quantityCount,
      sizeGrade: sizeGrade,
      containerCount: containerCount,
      storageLocationId: storageLocationId,
    );
  });

  Future<bool> submitPurchase({
    required String supplierId,
    required DateTime purchasedAt,
    double? weightKg,
    int? quantityCount,
    SizeGrade? sizeGrade,
    int? containerCount,
    String? storageLocationId,
  }) => _submit(() {
    final repository = _ref.read(harvestRepositoryProvider);
    return repository.recordPurchase(
      supplierId: supplierId,
      purchasedAt: purchasedAt,
      weightKg: weightKg,
      quantityCount: quantityCount,
      sizeGrade: sizeGrade,
      containerCount: containerCount,
      storageLocationId: storageLocationId,
    );
  });

  Future<bool> _submit(Future<void> Function() action) async {
    state = const AsyncValue.loading();
    try {
      await action();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final StateNotifierProvider<HarvestFormController, AsyncValue<void>>
harvestFormControllerProvider =
    StateNotifierProvider<HarvestFormController, AsyncValue<void>>(
      (ref) => HarvestFormController(ref),
    );

/// 品種・圃場・保管場所の選択肢はマスタ管理と同じ一覧を再利用する（T014）。
final varietyOptionsProvider = varietiesProvider;
final fieldOptionsProvider = fieldsProvider;
final supplierOptionsProvider = suppliersProvider;
final storageLocationOptionsProvider = storageLocationsProvider;
