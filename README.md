# キウイの国 在庫管理システム（kiwi_inventory）

株式会社ReFruits「キウイの国」向け在庫管理アプリ。要件定義書 v1.1（MVP先行リリース方式）に基づくプロジェクトです。

仕様・設計・タスクの詳細は [`specs/001-inventory-mvp/`](specs/001-inventory-mvp/)（spec-kit / Spec-Driven Development）を参照してください。

## 技術スタック

| レイヤ | 採用技術 | 理由 |
|---|---|---|
| フロントエンド | **Flutter (Dart) / Flutter Web** | モバイル・PCどちらのブラウザでも同一コードで動くレスポンシブなWebアプリを1つのコードベースで作れるため |
| 状態管理 | **flutter_riverpod** | テスト容易性・スケーラビリティのバランスがよい |
| ルーティング | **go_router** | Web URLベースのルーティングと、画面幅に応じたシェル切り替えがしやすい |
| バックエンド | **Supabase**（PostgreSQL + Auth + Row Level Security） | リレーショナルなデータ構造・SQL集計と相性が良く、Auth+RLSだけで現場スタッフ／管理者の2階層権限が組める |

## セットアップ手順

### 1. Flutterのインストール

[公式サイト](https://docs.flutter.dev/get-started/install) の手順に従い、安定版(stable)チャンネルをインストールしてください。`flutter doctor` で Web (Chrome) が有効になっていることを確認してください。

### 2. Supabaseプロジェクトの作成

1. https://supabase.com でアカウントを作成し、新規プロジェクトを作成
2. プロジェクトの `SQL Editor` で、`supabase/migrations/` 配下のファイルを**番号順に**実行（`0001_init_mvp.sql` → `0002_supplier_contract_date.sql`）
3. （任意・開発用データ）`supabase/seed.sql` も同様に実行
4. プロジェクトの `Project Settings > API` から `Project URL` と `anon public key` を控える
5. `Authentication > Users` から、現場スタッフ・管理者7名分のアカウントを作成（メール＋パスワード）。管理者にする場合は、作成後に `profiles` テーブルの該当ユーザーの `role` を `admin` に変更してください

### 3. 依存パッケージの取得

```bash
flutter pub get
```

### 4. 接続情報の設定（初回のみ）

毎回 `--dart-define` を並べなくて済むように、接続情報を1つのファイルにまとめておきます（このファイルはGitには含まれません）。

```bash
cp config/local.json.example config/local.json
# config/local.json を開き、Project URL / anon public key を書き込む
```

### 5. アプリの起動（ローカル確認）

```bash
flutter run -d web-server --web-port=8080 --dart-define-from-file=config/local.json
```

起動後、ブラウザで `http://localhost:8080` を開いてください。（Chromeが使える環境では `-d chrome` でも可）

値を毎回指定したい場合は、従来どおり個別に渡すこともできます:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=<Project URL> \
  --dart-define=SUPABASE_ANON_KEY=<anon public key>
```

### 6. Web向けビルド

```bash
flutter build web --dart-define-from-file=config/local.json
```

`build/web` 配下に静的ファイルが出力されます。任意のホスティング（Netlify, Vercel, Firebase Hosting等）にデプロイできます。

### 7. 品質チェック

```bash
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed lib test
```

## テスト戦略（constitution Principle II）

自動テストは3層のピラミッドで構成する。

1. **unit**（`test/*.dart`、`integration_test/`は含まない）: 純粋関数（例: `shipment_validation_test.dart`, `dashboard_metrics_test.dart`）と、`mocktail`でRepositoryをモック化したProvider/Controllerのテスト（例: `harvest_form_controller_test.dart`）。SupabaseClientを直接テストコードに埋め込むことはしない。
2. **widget**（golden）: `golden_toolkit` によるスクリーンショット差分テスト（例: `login_screen_golden_test.dart`）。基準画像（`test/goldens/*.png`）はCI環境で生成・更新したものを正とする。ローカルで意図的に見た目を変更した場合は `flutter test --update-goldens` で更新する。
3. **integration**（`integration_test/`）: `supabase start` で立てたローカルSupabaseスタック＋シードデータに対して実行し、RLSポリシーの検証も含む。ローカルで実行する場合:
   ```bash
   supabase start
   # supabase status の値と、事前に作成したテストユーザー（2名: 現場スタッフ・管理者）を使って:
   flutter test integration_test \
     --dart-define=SUPABASE_URL=<supabase status の API URL> \
     --dart-define=SUPABASE_ANON_KEY=<supabase status の anon key> \
     --dart-define=INTEGRATION_TEST_FIELD_STAFF_EMAIL=<現場スタッフのメール> \
     --dart-define=INTEGRATION_TEST_FIELD_STAFF_PASSWORD=<パスワード> \
     --dart-define=INTEGRATION_TEST_ADMIN_EMAIL=<管理者のメール> \
     --dart-define=INTEGRATION_TEST_ADMIN_PASSWORD=<パスワード>
   ```
   接続情報が未設定の場合、このテストは（誤って実行されても失敗しないよう）自動的にスキップされる。

CI（`.github/workflows/ci.yml`）は1ジョブ内で `flutter analyze` → unit/widgetテスト → `supabase start` → integrationテストの順に実行する（テストユーザーの作成も含む）。ローカル開発中は、`.claude/settings.json` のPostToolUseフックが `lib/` `test/`（`integration_test/`を除く）の `.dart` ファイル編集後に自動で `flutter test` を実行し、素早くフィードバックを返す。

## フォルダ構成

```
lib/
  main.dart                 # エントリポイント（Supabase初期化）
  app.dart                  # MaterialApp.router のルート
  core/
    config/env.dart         # --dart-define の環境変数
    theme/app_theme.dart    # 配色・LotStatus（ステータス）定義
    router/                 # go_router 設定、認証状態・役割によるリダイレクト
    widgets/                # ResponsiveScaffold など共通UI部品
    models/                 # Variety/FarmField/Supplier/StorageLocation/Lot/Shipment
    access/role_access.dart # 役割ベースのアクセス可否判定（FR-003）
    validation/             # 出荷数量バリデーション等の純粋関数（FR-017）
    logic/dashboard_metrics.dart # ホーム画面の集計ロジック（FR-013, FR-014）
    data/supabase_error_mapper.dart # エラーメッセージ変換（FR-018）
  features/
    auth/                   # ログイン（Supabase Auth）
    master_data/            # F1: 品種・圃場・仕入先・保管場所（管理者のみ）
    harvest/                # F2/F3: 収穫・仕入れ記録
    inventory/              # F4/F5: 在庫・追熟状況、ステータス変更・履歴
    shipping/                # F6: 出荷記録（在庫超過チェック含む）
    dashboard/               # F9: ホーム画面（追熟間近・在庫僅少）
supabase/
  migrations/                # MVPスキーマ（番号順に適用）
  seed.sql                   # 開発用サンプルデータ
integration_test/            # Supabaseローカルスタックに対するintegrationテスト
test/
  goldens/                   # golden_toolkitの基準画像
  flutter_test_config.dart   # golden_toolkit共通設定（フォント読み込み）
.github/workflows/ci.yml     # analyze → unit/widget → integration の1ジョブCI
specs/001-inventory-mvp/     # spec-kit の仕様・計画・タスク一式
```

## 現在の状態

`specs/001-inventory-mvp/tasks.md` の全タスク（Setup〜Polish）が完了し、5つのユーザーストーリー（P1〜P5、マスタ管理／収穫・仕入れ記録／在庫・追熟状況／出荷記録／ホーム画面）はすべて実装済みです。実Supabaseプロジェクトへの疎通確認は、上記セットアップ手順に沿って各自の環境で行ってください。
