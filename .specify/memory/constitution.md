<!--
Sync Impact Report
- Version change: (none) → 1.0.0
- Modified principles: n/a (initial ratification)
- Added sections: Core Principles (5), Technology Constraints, Development Workflow, Governance
- Removed sections: none
- Follow-up TODOs: RATIFICATION_DATE set to the date this constitution was first drafted (today); adjust if the client (株式会社ReFruits) formally signs off on a different date.
-->

# キウイの国 在庫管理システム Constitution

## Core Principles

### I. MVP優先・段階的リリース
機能は要件定義書 v1.1 12章で合意した範囲に厳密に従う。まず在庫管理の最低限機能（収穫記録・在庫/追熟状況・出荷記録・ダッシュボード・マスタ管理・ログイン権限）のみでリリースし、実際の現場利用とフィードバックを経てから追加ヒアリングに基づき次の機能を計画する。MVP範囲に含まれない機能（Shopify/freee連携、データ移行、体験プログラム消費記録など）は、明示的にPhase 2以降に切り出し、MVPの実装には含めない。

**Rationale**: エンドユーザー（ReFruits）は今年から収穫を開始したばかりで、実運用の勝手が定まっていない。先に全機能を作り込むより、小さく出して学ぶ方がリスクが低い。

### II. 現場での使いやすさ最優先
主要な利用者は私物スマートフォンを使う現場スタッフ5名である。すべての現場向け画面は、片手操作・大きなタップ領域・チップ選択やステッパーなど入力の手間を減らすUIを基本とする。PC（管理者2名）向けは同じコードベースのレスポンシブ表示で対応し、別アプリを作らない。

**Rationale**: 現場での入力が続かなければ在庫データそのものが蓄積されず、システムの目的（在庫の可視化）が達成できない。

### III. 誤操作は取り消せる、記録は消さない
現場での入力ミスは前提とする。ステータスなど記録済みの値は後から誰でも修正できる操作性を用意する一方、変更履歴（いつ・誰が・何を・どう変えたか）は自動的に記録し、修正によって過去の記録を消さない。

**Rationale**: 「間違って変更したときに直せるようにしてほしい」という現場からの明示的な要望と、将来的な集計・監査のためにデータの信頼性を両立させるため。

### IV. 要確認事項は推測せず明示する
仕様・データ項目・運用ルールのうち、ヒアリングで確定していない事項（等級・サイズ規格、仕入先の詳細、体験プログラム消費の扱いなど）は、実装側で勝手に仕様を決め打ちしない。`[NEEDS CLARIFICATION]` として明示するか、要件定義書13章の「要確認事項一覧」に立ち返って確認する。

**Rationale**: 推測で作り込むと、後から手戻りが発生し、MVP優先の原則(I)と矛盾する。

### V. シンプルさ優先（YAGNI）
MVPで使わない抽象化・汎用化・将来の拡張性のための複雑な設計は避ける。データモデルは要件定義書9章の実データに素直に対応させ、必要になった時点（Phase 2着手時）で分割・拡張する。

**Rationale**: 開発フェーズを分けて進める合意（要件定義書12章）に沿い、今作らなくてよいものは作らない。

## Technology Constraints

- フロントエンドは Flutter (Dart) による単一コードベースの Flutter Web アプリとし、現場（スマートフォンのブラウザ）と事務所・管理者（PCのブラウザ）の両方をレスポンシブ対応でカバーする。ネイティブアプリ配布は行わない。
- バックエンドは Supabase（PostgreSQL + Auth + Row Level Security）を採用する。認可は Supabase Auth + RLS（現場スタッフ／管理者の2階層、要件定義書7章 F11）で行い、独自の認可基盤は持たない。
- 環境変数（Supabase接続情報など）は `--dart-define` で注入し、Gitに秘密情報を含めない。
- Phase 2で計画されている外部連携（Shopify、freee）は、Supabase Edge Functions等の追加コンポーネントとして後から拡張する前提とし、MVPの設計を連携ありきで複雑化させない。

## Development Workflow

- 開発は spec-kit（Spec-Driven Development）に沿って進める: `/speckit-constitution`（本ドキュメント）→ `/speckit-specify`（機能仕様）→ 必要に応じ `/speckit-clarify` → `/speckit-plan`（技術実装計画）→ `/speckit-tasks`（タスク分解）→ 必要に応じ `/speckit-checklist` / `/speckit-analyze` → `/speckit-implement`（実装）。
- 仕様書（spec.md）はビジネス側（ReFruits）にも読める平易な言葉で、技術選定（Flutter/Supabaseなど）を含めずに「何を・なぜ」だけを書く。技術選定・設計は `/speckit-plan` 以降で扱う。
- 各フェーズの区切り（仕様確定時、実装計画確定時、MVPリリース時）で、開発会社（Bloomix）から利用者（ReFruits）へ内容を確認し、合意のうえで次工程に進む。

## Governance

本Constitutionは、本プロジェクトの spec-kit ワークフロー（specify/plan/tasks/implement）における判断より優先する。原則と矛盾する実装判断が必要になった場合は、実装を進める前に本ドキュメントの改訂を検討する。改訂はセマンティックバージョニングに従う（原則の削除・非互換な再定義は MAJOR、原則の追加は MINOR、文言修正は PATCH）。

**Version**: 1.0.0 | **Ratified**: 2026-09-01 | **Last Amended**: 2026-09-01
