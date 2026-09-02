import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/master_data.dart';

/// マスタ管理（品種・圃場・仕入先・保管場所）のSupabaseアクセスをまとめたリポジトリ。
///
/// Backend Boundary原則（constitution IV）に従い、Supabaseアクセスはこのクラスに
/// 閉じ込め、UI・状態管理側にはプレーンなDartモデル（Variety等）のみを渡す。
class MasterDataRepository {
  MasterDataRepository(this._client);

  final SupabaseClient _client;

  Future<List<Variety>> fetchVarieties() async {
    final rows = await _client.from('varieties').select().order('name');
    return rows.map(Variety.fromRow).toList();
  }

  Future<void> createVariety({
    required String name,
    int? standardRipeningDaysMin,
    int? standardRipeningDaysMax,
  }) async {
    await _client.from('varieties').insert({
      'name': name,
      'standard_ripening_days_min': standardRipeningDaysMin,
      'standard_ripening_days_max': standardRipeningDaysMax,
    });
  }

  Future<List<FarmField>> fetchFields() async {
    final rows = await _client.from('fields').select().order('name');
    return rows.map(FarmField.fromRow).toList();
  }

  Future<void> createField({required String name, String? location}) async {
    await _client.from('fields').insert({'name': name, 'location': location});
  }

  Future<List<Supplier>> fetchSuppliers() async {
    final rows = await _client.from('suppliers').select().order('name');
    return rows.map(Supplier.fromRow).toList();
  }

  Future<void> createSupplier({
    required String name,
    String? location,
    String? contact,
    DateTime? contractStartedAt,
  }) async {
    await _client.from('suppliers').insert({
      'name': name,
      'location': location,
      'contact': contact,
      'contract_started_at': contractStartedAt == null
          ? null
          : _formatDate(contractStartedAt),
    });
  }

  Future<List<StorageLocation>> fetchStorageLocations() async {
    final rows = await _client.from('storage_locations').select().order(
      'name',
    );
    return rows.map(StorageLocation.fromRow).toList();
  }

  Future<void> createStorageLocation({required String name}) async {
    await _client.from('storage_locations').insert({'name': name});
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
