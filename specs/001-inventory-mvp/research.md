# Phase 0 Research: キウイ在庫管理 MVP

Technical Contextに`NEEDS CLARIFICATION`は残っていない（スキャフォールド作成時点・`/speckit-clarify`で解消済み）。本ドキュメントは、すでになされた技術選定の根拠を後から追跡できるよう記録する。

## バックエンド: Supabase

- **Decision**: Supabase（PostgreSQL + Auth + Row Level Security）を採用する。
- **Rationale**: 在庫ロット・出荷・仕入といったリレーショナルなデータ構造とSQL集計（品種別・仕入先別など）に向いている。`supabase_flutter`のSDKが成熟しており、Auth+RLSだけで「現場スタッフ／管理者」の2階層権限（FR-003）を実装できる。7名規模のMVPには無料〜低コストで十分。
- **Alternatives considered**: Firebase（Firestore）はドキュメント指向でリレーショナルな集計に不向きなため見送り。独自バックエンド（Node/Go等の自前API）はMVP規模には過剰でPrinciple V（YAGNI）に反するため見送り。

## 状態管理: Riverpod

- **Decision**: `flutter_riverpod` を採用する。
- **Rationale**: テスト容易性（Providerのoverrideでフェイクリポジトリに差し替え可能）とスケーラビリティのバランスが良く、Flutterの標準的選択肢の一つ。Backend Boundary原則（Supabase呼び出しをリポジトリ層に閉じ込める）ともなじみが良い。
- **Alternatives considered**: `provider`単体は非同期状態の扱いがやや冗長。`bloc`はMVP規模に対してボイラープレートが多く、Principle V（シンプルさ優先）に反するため見送り。

## ルーティング: go_router

- **Decision**: `go_router` を採用し、Supabaseの認証状態を`GoRouterRefreshStream`経由で監視してログイン/未ログインをリダイレクトする。
- **Rationale**: Web URLベースのルーティングと、画面幅に応じたシェル切り替え（`StatefulShellRoute`）がしやすく、レスポンシブ対応（Principle II）と相性が良い。
- **Alternatives considered**: `Navigator 2.0`の素実装は認証ガード・ネストされたシェルの実装コストが高く見送り。

## サイズ・等級区分（FR-016）

- **Decision**: S/M/L/2Lの4区分をマスタ選択式（自由入力ではなく固定の選択肢）として`lots.size_grade`に保存する。
- **Rationale**: `/speckit-clarify`で確定。選択式にすることで在庫一覧の絞り込み・集計が可能になり、社内基準確定後も選択肢の追加・変更だけで対応できる。
- **Alternatives considered**: 自由入力（集計・絞り込みができず却下）、サイズ記録自体を見送る案（要件定義書9章のデータ項目に反するため却下）。

## 出荷数量の在庫超過チェック（FR-017）

- **Decision**: 出荷記録保存前に、対象ロットの残り在庫数量（`weight_kg` または `quantity_count` から既存出荷分を差し引いた値）を上回る入力をクライアント側でバリデーションし、保存をブロックする。
- **Rationale**: `/speckit-clarify`で確定。在庫の正確性がシステムの中心目的（SC-002）であり、マイナス在庫は現場の混乱を招く。
- **Alternatives considered**: 警告のみで保存を許可する案は誤操作の是正コストが高く却下。将来的にDB側の`check`制約やトリガーでの二重チェックも検討可能（tasks.mdで扱う）。

## オフライン対応（FR-018）

- **Decision**: MVPではオフライン時のデータ保存・自動同期は実装しない。保存に失敗した場合は分かりやすいエラーメッセージを表示し、通信復旧後の再試行を促す。
- **Rationale**: `/speckit-clarify`で確定。要件定義書に明確な合意がなく、オフライン同期は実装コストが高いためPrinciple I（MVP優先）・V（YAGNI）に沿って見送る。
- **Alternatives considered**: ローカルキュー＋自動同期は技術的に可能だが、競合解決（同一ロットへの同時更新）の設計コストが高くMVPの範囲を超えるため却下。

## 仕入先マスタの項目粒度

- **Decision**: 仕入先名・連絡先（電話番号またはメールアドレス）・住所・取引開始日を保持する。
- **Rationale**: `/speckit-clarify`で確定。既存マイグレーションの`suppliers`テーブルには`location`（住所相当）はあるが`取引開始日`が無いため、Phase 1で列追加が必要（data-model.md参照）。
- **Alternatives considered**: 仕入先名のみの最小構成は緊急連絡や取引経緯の把握ができず却下。

## テスト方針

- **Decision**: Supabase依存はリポジトリのインターフェース（例: `AuthRepository`）を介して抽象化し、ユニットテストではフェイク実装に差し替える。ウィジェットテストは各ユーザーストーリーの主要フロー1本ずつを目安とする（Principle II: 非自明なロジックはユニットテスト必須、UI主要フローはウィジェット/統合テスト推奨）。
- **Rationale**: 実際のSupabaseプロジェクトに依存しないテストにすることで、CI（`.github/workflows/ci.yml`相当）でも安定して実行できる。
- **Alternatives considered**: 実Supabaseプロジェクトに対する統合テストはMVP段階では環境準備コストが高く、tasks.mdでは対象外とし今後の課題とする。
