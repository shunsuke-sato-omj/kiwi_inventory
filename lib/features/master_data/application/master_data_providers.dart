import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/master_data.dart';
import '../../auth/application/auth_providers.dart';
import '../data/master_data_repository.dart';

final Provider<MasterDataRepository> masterDataRepositoryProvider =
    Provider<MasterDataRepository>(
      (ref) => MasterDataRepository(ref.watch(supabaseClientProvider)),
    );

/// 品種一覧。収穫記録画面（harvest）のドロップダウン/チップ選択でも再利用する。
final FutureProvider<List<Variety>> varietiesProvider =
    FutureProvider<List<Variety>>(
      (ref) => ref.watch(masterDataRepositoryProvider).fetchVarieties(),
    );

/// 圃場一覧。
final FutureProvider<List<FarmField>> fieldsProvider =
    FutureProvider<List<FarmField>>(
      (ref) => ref.watch(masterDataRepositoryProvider).fetchFields(),
    );

/// 仕入先一覧。
final FutureProvider<List<Supplier>> suppliersProvider =
    FutureProvider<List<Supplier>>(
      (ref) => ref.watch(masterDataRepositoryProvider).fetchSuppliers(),
    );

/// 保管場所一覧。
final FutureProvider<List<StorageLocation>> storageLocationsProvider =
    FutureProvider<List<StorageLocation>>(
      (ref) => ref.watch(masterDataRepositoryProvider).fetchStorageLocations(),
    );
