import '../../features/auth/data/auth_repository.dart';

/// 役割ごとのアクセス可否を1箇所に集約する純粋関数群。
///
/// FR-003: マスタ管理は管理者のみが行える。UI（ナビゲーション表示）と
/// ルーティング（リダイレクト）の両方からこの関数を参照することで、
/// 判定基準がずれないようにする。
bool canManageMasterData(UserRole role) => role == UserRole.admin;
