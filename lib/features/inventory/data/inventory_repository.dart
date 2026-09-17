import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/lot.dart';
import '../../../core/theme/app_theme.dart';

/// 在庫ロットの一覧・ステータス変更・変更履歴を扱うリポジトリ（FR-007〜FR-010）。
class InventoryRepository {
  InventoryRepository(this._client);

  final SupabaseClient _client;

  /// [statusFilter] が null の場合はすべてのロットを返す（FR-010）。
  Future<List<Lot>> fetchLots({LotStatus? statusFilter}) async {
    var query = _client.from('lots').select('*, varieties(name)');
    if (statusFilter != null) {
      query = query.eq('status', statusFilter.dbValue);
    }
    final rows = await query.order(
      'harvested_or_purchased_at',
      ascending: false,
    );
    return rows.map(Lot.fromRow).toList();
  }

  /// 現在の状態に関わらず、いずれの状態にも手動変更できる（FR-008、誤操作の訂正含む）。
  /// 変更は `lots` テーブルのトリガーにより自動的に `lot_status_history` に記録される（FR-009）。
  ///
  /// `lots` への直接UPDATEは（ステータス以外のカラムも書き換えられてしまうため）
  /// RLSで禁止しており、ステータス変更は専用のRPC関数
  /// `update_lot_status`（security definer、statusのみ更新）を経由する
  /// （supabase/migrations/0003_fix_rls_and_atomicity.sql参照）。
  Future<void> updateStatus({
    required String lotId,
    required LotStatus newStatus,
  }) async {
    await _client.rpc(
      'update_lot_status',
      params: {'p_lot_id': lotId, 'p_new_status': newStatus.dbValue},
    );
  }

  /// 指定ロットのステータス変更履歴を新しい順に返す（FR-009）。
  Future<List<LotStatusHistoryEntry>> fetchStatusHistory(String lotId) async {
    final rows = await _client
        .from('lot_status_history')
        .select()
        .eq('lot_id', lotId)
        .order('changed_at', ascending: false);
    return rows.map(LotStatusHistoryEntry.fromRow).toList();
  }
}
