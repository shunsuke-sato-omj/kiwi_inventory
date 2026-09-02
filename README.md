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

### 4. アプリの起動（ローカル確認）

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=<Project URL> \
  --dart-define=SUPABASE_ANON_KEY=<anon public key>
```

### 5. Web向けビルド

```bash
flutter build web \
  --dart-define=SUPABASE_URL=<Project URL> \
  --dart-define=SUPABASE_ANON_KEY=<anon public key>
```

`build/web` 配下に静的ファイルが出力されます。任意のホスティング（Netlify, Vercel, Firebase Hosting等）にデプロイできます。

### 6. 品質チェック

```bash
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed lib test
```

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
specs/001-inventory-mvp/     # spec-kit の仕様・計画・タスク一式
```

## 現在の状態

`specs/001-inventory-mvp/tasks.md` の全タスク（Setup〜Polish）が完了し、5つのユーザーストーリー（P1〜P5、マスタ管理／収穫・仕入れ記録／在庫・追熟状況／出荷記録／ホーム画面）はすべて実装済みです。実Supabaseプロジェクトへの疎通確認は、上記セットアップ手順に沿って各自の環境で行ってください。
