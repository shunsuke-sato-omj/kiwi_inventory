import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logic/dashboard_metrics.dart';
import '../../../core/models/lot.dart';
import '../../../core/models/master_data.dart';
import '../../auth/application/auth_providers.dart';
import '../data/dashboard_repository.dart';

final Provider<DashboardRepository> dashboardRepositoryProvider =
    Provider<DashboardRepository>(
      (ref) => DashboardRepository(ref.watch(supabaseClientProvider)),
    );

final FutureProvider<List<Lot>> activeLotsProvider = FutureProvider<List<Lot>>((
  ref,
) {
  // ログイン状態が変わるたびに再取得する（別ユーザーへの切り替え時に
  // 前のユーザーのデータが残らないようにするため）。
  ref.watch(authStateChangesProvider);
  return ref.watch(dashboardRepositoryProvider).fetchActiveLots();
});

final FutureProvider<List<Variety>> dashboardVarietiesProvider =
    FutureProvider<List<Variety>>((ref) {
      ref.watch(authStateChangesProvider);
      return ref.watch(dashboardRepositoryProvider).fetchVarieties();
    });

/// ロットIDごとの出荷済み数量合計。「在庫が少ない品種」（FR-014）の
/// 残り在庫算出に使う。
final FutureProvider<Map<String, num>> shippedTotalsProvider =
    FutureProvider<Map<String, num>>((ref) {
      ref.watch(authStateChangesProvider);
      return ref.watch(dashboardRepositoryProvider).fetchShippedTotals();
    });

/// 「追熟完了が近いロット」（FR-013）。
final FutureProvider<List<Lot>> nearingRipenessLotsProvider =
    FutureProvider<List<Lot>>((ref) async {
      final lots = await ref.watch(activeLotsProvider.future);
      final varieties = await ref.watch(dashboardVarietiesProvider.future);
      return lotsNearingRipeness(lots, varieties);
    });

/// 「在庫が少ない品種」（FR-014）。
final FutureProvider<List<Variety>> lowStockVarietiesProvider =
    FutureProvider<List<Variety>>((ref) async {
      final lots = await ref.watch(activeLotsProvider.future);
      final varieties = await ref.watch(dashboardVarietiesProvider.future);
      final shippedTotals = await ref.watch(shippedTotalsProvider.future);
      return lowStockVarieties(lots, varieties, shippedTotalsKg: shippedTotals);
    });
