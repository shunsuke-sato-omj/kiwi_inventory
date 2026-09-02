# Implementation Plan: キウイ在庫管理 MVP

**Branch**: `001-inventory-mvp` | **Date**: 2026-09-02 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-inventory-mvp/spec.md`

## Summary

株式会社ReFruits「キウイの国」の現場スタッフ・管理者向けに、収穫・仕入れの記録から在庫・追熟状況の確認、出荷記録、ホーム画面での状況把握までを行う最小構成の在庫管理システムを、Flutter Web（レスポンシブ）+ Supabase（PostgreSQL / Auth / RLS）で実装する。技術選定・スキーマ・画面雛形はすでにスキャフォールドとして存在しており（`lib/`, `supabase/migrations/0001_init_mvp.sql`）、本計画はその構造を踏襲しつつ、5つのユーザーストーリー（P1〜P5）を実装に落とし込む。

## Technical Context

**Language/Version**: Dart (SDK `^3.13.2`) / Flutter stable channel

**Primary Dependencies**: `flutter_riverpod`（状態管理）, `go_router`（ルーティング・認証ガード）, `supabase_flutter`（Auth / Postgres / Realtime）, `intl`（日付・数値表示）, `equatable`（値オブジェクト比較）, `collection`, `logging`

**Storage**: Supabase（PostgreSQL + Row Level Security）。スキーマは `supabase/migrations/0001_init_mvp.sql` に定義済み（profiles, varieties, fields, suppliers, storage_locations, lots, lot_status_history, shipments）

**Testing**: `flutter_test`（ユニット・ウィジェット）。Supabase依存部分はリポジトリ層をインターフェースで抽象化し、フェイク実装によるユニットテストを可能にする

**Target Platform**: Flutter Web（レスポンシブ）。現場スタッフの私物スマートフォンのブラウザ／管理者PCのブラウザの両方を1コードベースでカバーし、ネイティブアプリ配布は行わない（constitution 技術制約）

**Project Type**: Web application（single Flutter codebase, レスポンシブ）

**Performance Goals**: SC-002（在庫状況を10秒以内に確認）、SC-006（ホーム画面を開いて5秒以内に対応要在庫を把握）を満たす応答性。利用者7名程度の同時アクセスを想定した小規模構成のため、高スループットは不要

**Constraints**:
- FR-017: 出荷数量は残り在庫数量を超える保存をブロックする（クライアント側バリデーション + 可能ならDB制約）
- FR-018: オフライン時のデータ保存・自動同期はMVP対象外。保存失敗時は分かりやすいエラー表示のみ行う
- Principle II（現場での使いやすさ最優先）: 現場向け画面は片手操作・大きなタップ領域・チップ選択/ステッパー中心のUIとする
- Principle IV（Backend Boundary）: Supabaseアクセスはリポジトリ層に閉じ込め、UIから直接呼び出さない

**Scale/Scope**: 利用者7名（現場スタッフ5名・管理者2名）。画面数はユーザーストーリー5件に対応する6画面程度（ログイン／マスタ管理／収穫・仕入れ記録／在庫一覧／出荷記録／ホーム）

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| 原則 | 判定 | 根拠 |
|---|---|---|
| I. MVP優先・段階的リリース | PASS | 対象はspec.mdの5ユーザーストーリー（P1〜P5）のみ。Shopify/freee連携・体験プログラム消費記録はPhase 2として明示的にスコープ外 |
| II. 現場での使いやすさ最優先 | PASS | Flutter Webの単一コードベース＋`ResponsiveScaffold`でスマホ／PCをレスポンシブ対応。収穫記録・出荷記録フォームはチップ選択／ステッパーを基本とする（tasks.mdで具体化） |
| III. 誤操作は取り消せる、記録は消さない | PASS | `lots`テーブルへのUPDATEトリガーで`lot_status_history`に全変更を自動記録済み（アプリ側の直接INSERTは許可しないRLS方針）。FR-008/009に対応 |
| IV. 要確認事項は推測せず明示する | PASS | 2026-09-02の`/speckit-clarify`でサイズ区分・出荷数量超過・オフライン・仕入先項目を暫定方針として明示し、spec.mdに記録済み（推測での実装なし） |
| V. シンプルさ優先（YAGNI） | PASS | 収穫・仕入・追熟・在庫を`lots`1テーブルに統合するなど、MVP規模に対して過剰な抽象化を避けた設計を踏襲 |

**違反なし。Complexity Trackingへの記載は不要。**

## Project Structure

### Documentation (this feature)

```text
specs/001-inventory-mvp/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output（Supabaseスキーマ＝契約であることを説明）
└── tasks.md             # Phase 2 output（/speckit-tasks）
```

### Source Code (repository root)

```text
lib/
├── main.dart                          # エントリポイント（Supabase初期化）
├── app.dart                           # MaterialApp.router のルート
├── core/
│   ├── config/env.dart                # --dart-define 環境変数
│   ├── theme/app_theme.dart           # 配色・LotStatus定義
│   ├── router/                        # go_router 設定・認証ガード
│   └── widgets/                       # ResponsiveScaffold 等共通UI部品
└── features/
    ├── auth/                          # ログイン（Supabase Auth）
    ├── master_data/                   # F1: 品種・圃場・仕入先・保管場所
    ├── harvest/                       # F2/F3: 収穫・仕入れ記録
    ├── inventory/                     # F4/F5: 在庫・追熟状況、ステータス訂正
    ├── shipping/                      # F6: 出荷記録
    └── dashboard/                     # F9: ホーム画面（追熟間近・在庫僅少）

test/
├── lot_status_test.dart               # 既存：LotStatusのラベル
└── (tasks.mdで追加するユニット/ウィジェットテスト)

supabase/
├── migrations/0001_init_mvp.sql       # 既存スキーマ（本featureで一部拡張）
└── seed.sql
```

**Structure Decision**: 既存スキャフォールドの `features/*` ディレクトリ構成（機能別: presentation/application/data の3層）をそのまま採用する。各featureは `data/`（Supabaseリポジトリ）→ `application/`（Riverpodプロバイダ・状態）→ `presentation/`（画面）の順に依存し、UIからのSupabase直接呼び出しは行わない（Principle IV）。

## Complexity Tracking

*違反なし（このセクションは空でよい）*
