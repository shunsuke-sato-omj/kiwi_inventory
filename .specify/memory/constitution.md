<!--
Sync Impact Report
- Version change: 1.0.0 → 1.1.0
- Modified principles:
  - II. Test Coverage for Business Logic → II. テスト戦略（3層のテストピラミッド）
    （旧原則の「非自明なビジネスロジックには自動テストが必須」という要求を包含したうえで、
    テストの層構成・モック方針・テストファースト・CI実行順序まで具体化した）
- Added sections: none（Core Principlesの1原則を拡張。Technology Constraints / Development
  Workflowに関連する記載を追加）
- Removed sections: none
- Templates requiring updates:
  - .specify/templates/tasks-template.md ⚠ 別途 `/speckit-tasks` 実行時にテストタスクを
    実装タスクより前に配置するルールとして反映すること（本コマンドの対象外）
  - .github/workflows/ci.yml ⚠ 本原則に沿った新規作成が必要（本コマンドの対象外）
  - .claude/settings.json（PostToolUseフック） ⚠ 別途 update-config スキルで設定が必要
    （本コマンドの対象外）
- Follow-up TODOs: none
-->

# キウイの国 在庫管理システム Constitution

## Core Principles

### I. MVP優先・段階的リリース
機能は要件定義書 v1.1 12章で合意した範囲に厳密に従う。まず在庫管理の最低限機能（収穫記録・在庫/追熟状況・出荷記録・ダッシュボード・マスタ管理・ログイン権限）のみでリリースし、実際の現場利用とフィードバックを経てから追加ヒアリングに基づき次の機能を計画する。MVP範囲に含まれない機能（Shopify/freee連携、データ移行、体験プログラム消費記録など）は、明示的にPhase 2以降に切り出し、MVPの実装には含めない。

**Rationale**: エンドユーザー（ReFruits）は今年から収穫を開始したばかりで、実運用の勝手が定まっていない。先に全機能を作り込むより、小さく出して学ぶ方がリスクが低い。

### II. テスト戦略（3層のテストピラミッド）
自動テストは以下の3層で構成し、下位の層ほど厚く（数が多く・速く）、上位の層ほど薄く（数は絞り、実環境に近い）保つ。

- **unit**: 純粋関数（ロジック層。例: 在庫超過チェック、ダッシュボード集計、権限判定）と、Repositoryに依存するコード（Provider・Controller等）を対象にする。Repositoryに依存するコードのテストは、`mocktail` でRepositoryをモック化する。**SupabaseClientをテストコードに直接埋め込んではならない**。Supabaseへの依存は Principle IV（Backend Boundary）のとおりRepository層に閉じ込め、テストはそのRepositoryの抽象をモック化する対象とする。
- **widget**: 画面単体を対象に、`golden_toolkit` を用いたスクリーンショット差分（golden）テストで検知する。goldenの基準画像はCI環境で生成・更新したものを正とする（開発者ごとのOS/フォント差によるフレークを避けるため）。
- **integration**: `integration_test`（Flutter公式パッケージ、Web/Chrome対応）を用い、`supabase start` で起動したローカルDocker上のSupabaseスタックとシードデータに対して実行する。Row Level Securityポリシーの検証（役割ごとのアクセス可否）もこの層で行う。iOS/Android前提の `patrol` は採用しない（Technology Constraintsのとおり、本プロジェクトはFlutter Web単一コードベースでネイティブアプリ配布を行わないため）。

新機能のタスク分解（`/speckit-tasks`）では、各ユーザーストーリー内で対応するテストタスクを実装タスクより前に配置する（テストファースト）。非自明なビジネスロジックにユニットテストが無い状態、主要画面にwidget/goldenテストが無い状態は「完了」とみなさない。

**Rationale**: Automated tests are the cheapest way to keep a solo/small-team project safe to change as Supabase schemas and screens evolve。層を分けることで、日常の開発ループ（unit/widget、高速）と、Supabase実環境・RLSまで含めた最終確認（integration、低頻度・高信頼）を両立できる。

### III. 現場での使いやすさ最優先
主要な利用者は私物スマートフォンを使う現場スタッフ5名である。すべての現場向け画面は、片手操作・大きなタップ領域・チップ選択やステッパーなど入力の手間を減らすUIを基本とする。PC（管理者2名）向けは同じコードベースのレスポンシブ表示で対応し、別アプリを作らない。

**Rationale**: 現場での入力が続かなければ在庫データそのものが蓄積されず、システムの目的（在庫の可視化）が達成できない。

### IV. 誤操作は取り消せる、記録は消さない
現場での入力ミスは前提とする。ステータスなど記録済みの値は後から誰でも修正できる操作性を用意する一方、変更履歴（いつ・誰が・何を・どう変えたか）は自動的に記録し、修正によって過去の記録を消さない。

**Rationale**: 「間違って変更したときに直せるようにしてほしい」という現場からの明示的な要望と、将来的な集計・監査のためにデータの信頼性を両立させるため。

### V. 要確認事項は推測せず明示する
仕様・データ項目・運用ルールのうち、ヒアリングで確定していない事項（等級・サイズ規格、仕入先の詳細、体験プログラム消費の扱いなど）は、実装側で勝手に仕様を決め打ちしない。`[NEEDS CLARIFICATION]` として明示するか、要件定義書13章の「要確認事項一覧」に立ち返って確認する。

**Rationale**: 推測で作り込むと、後から手戻りが発生し、MVP優先の原則(I)と矛盾する。

### VI. シンプルさ優先（YAGNI）
MVPで使わない抽象化・汎用化・将来の拡張性のための複雑な設計は避ける。データモデルは要件定義書9章の実データに素直に対応させ、必要になった時点（Phase 2着手時）で分割・拡張する。

**Rationale**: 開発フェーズを分けて進める合意（要件定義書12章）に沿い、今作らなくてよいものは作らない。

## Technology Constraints

- フロントエンドは Flutter (Dart) による単一コードベースの Flutter Web アプリとし、現場（スマートフォンのブラウザ）と事務所・管理者（PCのブラウザ）の両方をレスポンシブ対応でカバーする。ネイティブアプリ配布は行わない。
- バックエンドは Supabase（PostgreSQL + Auth + Row Level Security）を採用する。認可は Supabase Auth + RLS（現場スタッフ／管理者の2階層、要件定義書7章 F11）で行い、独自の認可基盤は持たない。
- 環境変数（Supabase接続情報など）は `--dart-define` で注入し、Gitに秘密情報を含めない。
- Phase 2で計画されている外部連携（Shopify、freee）は、Supabase Edge Functions等の追加コンポーネントとして後から拡張する前提とし、MVPの設計を連携ありきで複雑化させない。
- テストツールは `mocktail`（unitでのRepositoryモック）・`golden_toolkit`（widget/goldenテスト）・`integration_test`（Flutter公式、Web/Chrome対応のintegrationテスト）を用いる。iOS/Android前提の `patrol` は上記のとおり不採用とする。

## Development Workflow

- 開発は spec-kit（Spec-Driven Development）に沿って進める: `/speckit-constitution`（本ドキュメント）→ `/speckit-specify`（機能仕様）→ 必要に応じ `/speckit-clarify` → `/speckit-plan`（技術実装計画）→ `/speckit-tasks`（タスク分解）→ 必要に応じ `/speckit-checklist` / `/speckit-analyze` → `/speckit-implement`（実装）。
- 仕様書（spec.md）はビジネス側（ReFruits）にも読める平易な言葉で、技術選定（Flutter/Supabaseなど）を含めずに「何を・なぜ」だけを書く。技術選定・設計は `/speckit-plan` 以降で扱う。
- 各フェーズの区切り（仕様確定時、実装計画確定時、MVPリリース時）で、開発会社（Bloomix）から利用者（ReFruits）へ内容を確認し、合意のうえで次工程に進む。
- ローカル開発中は、ファイル編集のたびに unit/widgetテスト（`flutter test`、`integration_test/` は含めない）を自動実行し、素早くフィードバックを得る。
- CI（GitHub Actions）では、1つのジョブ内で `flutter analyze` → unit/widgetテスト（`flutter test`）→ ローカルSupabaseスタック起動（`supabase start`）→ integrationテスト、の順に実行する。本プロジェクトはFlutter Web単一コードベース（ネイティブ配布なし）のため、プラットフォームのマトリクス化は行わない。

## Governance

本Constitutionは、本プロジェクトの spec-kit ワークフロー（specify/plan/tasks/implement）における判断より優先する。原則と矛盾する実装判断が必要になった場合は、実装を進める前に本ドキュメントの改訂を検討する。改訂はセマンティックバージョニングに従う（原則の削除・非互換な再定義は MAJOR、原則の追加は MINOR、文言修正は PATCH）。

**Version**: 1.1.0 | **Ratified**: 2026-09-01 | **Last Amended**: 2026-09-02
