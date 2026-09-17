import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';

/// アプリ全体で共有する Supabase クライアント。
/// main.dart で `Supabase.initialize()` を実行済みであることが前提。
final Provider<SupabaseClient> supabaseClientProvider =
    Provider<SupabaseClient>((ref) => Supabase.instance.client);

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>(
      (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
    );

/// ログイン状態の変化を監視する Stream。go_router のリダイレクト判定に使う。
final StreamProvider<AuthState> authStateChangesProvider =
    StreamProvider<AuthState>(
      (ref) => ref.watch(authRepositoryProvider).authStateChanges,
    );

/// 現在ログイン中のユーザーの役割（現場スタッフ／管理者）。
final FutureProvider<UserRole> currentUserRoleProvider =
    FutureProvider<UserRole>((ref) async {
      // ログイン状態が変わるたびに再取得する。
      ref.watch(authStateChangesProvider);
      return ref.watch(authRepositoryProvider).fetchCurrentUserRole();
    });
