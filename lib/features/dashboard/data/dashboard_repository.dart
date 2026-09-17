import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/lot.dart';
import '../../../core/models/master_data.dart';

/// ホーム画面（FR-013, FR-014）に必要なデータをまとめて取得するリポジトリ。
class DashboardRepository {
  DashboardRepository(this._client);

  final SupabaseClient _client;

  Future<List<Lot>> fetchActiveLots() async {
    final rows = await _client
        .from('lots')
        .select('*, varieties(name)')
        .neq('status', 'expired');
    return rows.map(Lot.fromRow).toList();
  }

  Future<List<Variety>> fetchVarieties() async {
    final rows = await _client.from('varieties').select().order('name');
    return rows.map(Variety.fromRow).toList();
  }

  /// ロットIDごとの出荷済み数量合計（FR-014の「残り在庫」算出に使う）。
  Future<Map<String, num>> fetchShippedTotals() async {
    final rows = await _client.from('shipments').select('lot_id, quantity_kg');
    final totals = <String, num>{};
    for (final row in rows) {
      final String lotId = row['lot_id'] as String;
      final num quantity = (row['quantity_kg'] as num?) ?? 0;
      totals[lotId] = (totals[lotId] ?? 0) + quantity;
    }
    return totals;
  }
}
