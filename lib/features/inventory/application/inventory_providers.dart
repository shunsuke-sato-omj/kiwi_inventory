import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/lot.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_providers.dart';
import '../data/inventory_repository.dart';

final Provider<InventoryRepository> inventoryRepositoryProvider =
    Provider<InventoryRepository>(
      (ref) => InventoryRepository(ref.watch(supabaseClientProvider)),
    );

/// 在庫一覧のステータス絞り込み条件。null = すべて表示（FR-010）。
final StateProvider<LotStatus?> inventoryStatusFilterProvider =
    StateProvider<LotStatus?>((ref) => null);

/// 絞り込み条件に連動する在庫ロット一覧。
final FutureProvider<List<Lot>> filteredLotsProvider =
    FutureProvider<List<Lot>>((ref) {
      final filter = ref.watch(inventoryStatusFilterProvider);
      return ref
          .watch(inventoryRepositoryProvider)
          .fetchLots(statusFilter: filter);
    });

/// 指定ロットのステータス変更履歴（FR-009）。
final lotStatusHistoryProvider =
    FutureProvider.family<List<LotStatusHistoryEntry>, String>(
      (ref, lotId) =>
          ref.watch(inventoryRepositoryProvider).fetchStatusHistory(lotId),
    );
