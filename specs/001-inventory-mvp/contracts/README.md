# Contracts: キウイ在庫管理 MVP

このアプリは独自のバックエンドAPIを持たず、Supabaseが自動生成するPostgREST API（+ Supabase Auth）を直接契約として利用する。したがって「契約」は独自OpenAPI等ではなく、以下の2点で構成される。

## 1. データベーススキーマ = 契約

`supabase/migrations/0001_init_mvp.sql`（および本featureで追加する`0002_supplier_contract_date.sql`）が、Flutterクライアントとバックエンド間の契約そのものである。テーブル定義・型・RLSポリシーの詳細は [data-model.md](../data-model.md) を参照。

- クライアントはこのスキーマに対し、`supabase_flutter`経由でPostgREST（`from('lots').select()...`等）を呼び出す。
- RLSポリシーにより、閲覧は認証済みユーザー全員、マスタ管理（varieties/fields/suppliers/storage_locations）の書き込みは管理者ロールのみに制限される（FR-003）。

## 2. リポジトリ層のインターフェース = アプリ内部の契約

Backend Boundary原則（constitution IV）により、UI層はSupabaseを直接呼び出さず、`features/*/data/`のリポジトリクラスを介してアクセスする。各featureが実装すべき最小インターフェースをtasks.mdで定義する。例（認証）:

```dart
abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;
  Future<void> signInWithPassword({required String email, required String password});
  Future<void> signOut();
}
```

- 戻り値は`PostgrestException`等のSupabase固有型ではなく、アプリ内のプレーンな型（`AppUser`, `Lot`, `Shipment`等）とする。
- ユニットテストでは、この抽象に対するフェイク実装を用いて、実Supabaseなしでビジネスロジック（在庫超過チェック等）を検証する。
