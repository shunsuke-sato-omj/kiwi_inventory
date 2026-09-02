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
}
