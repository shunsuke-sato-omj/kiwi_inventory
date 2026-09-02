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

final FutureProvider<List<Lot>> activeLotsProvider = FutureProvider<List<Lot>>(
  (ref) => ref.watch(dashboardRepositoryProvider).fetchActiveLots(),
);

final FutureProvider<List<Variety>> dashboardVarietiesProvider =
    FutureProvider<List<Variety>>(
      (ref) => ref.watch(dashboardRepositoryProvider).fetchVarieties(),
    );

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
      return lowStockVarieties(lots, varieties);
    });
