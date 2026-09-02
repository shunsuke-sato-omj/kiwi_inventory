import 'package:supabase_flutter/supabase_flutter.dart';

/// ユーザーの役割。要件定義書 7章 F11（現場スタッフ／管理者の2階層）に対応。
///
/// 実際の役割は Supabase 側の `profiles` テーブル（supabase/migrations参照）に
/// 保持し、Row Level Security のポリシーでアクセス範囲を制御する想定。
enum UserRole { fieldStaff, admin }

extension UserRoleX on UserRole {
  static UserRole fromDb(String value) => switch (value) {
    'admin' => UserRole.admin,
    _ => UserRole.fieldStaff,
  };

  String get label => switch (this) {
    UserRole.admin => '管理者',
    UserRole.fieldStaff => '現場スタッフ',
  };
}

/// Supabase Auth のラッパー。
///
/// 画面・状態管理側からは Supabase SDK を直接触らず、必ずこのクラス経由にする
/// ことで、将来バックエンドを差し替える場合の影響範囲を限定する。
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// `profiles` テーブルから役割を取得する。
  /// MVPでは現場スタッフ／管理者の2階層のみ（要件定義書 7章 F11）。
  Future<UserRole> fetchCurrentUserRole() async {
    final String? uid = currentUser?.id;
    if (uid == null) return UserRole.fieldStaff;

    final Map<String, dynamic>? row = await _client
        .from('profiles')
        .select('role')
        .eq('id', uid)
        .maybeSingle();

    final String roleValue = (row?['role'] as String?) ?? 'field_staff';
    return UserRoleX.fromDb(roleValue);
  }
}
