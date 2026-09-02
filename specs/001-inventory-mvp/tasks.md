---

description: "Task list template for feature implementation"
---

# Tasks: キウイ在庫管理 MVP

**Input**: Design documents from `/specs/001-inventory-mvp/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: constitution Principle II (NON-NEGOTIABLE)により、非自明なビジネスロジック（在庫超過チェック・ダッシュボード集計・権限判定）にはユニットテストを含める。単純なCRUDのpassthrough自体はテスト対象外とする。

**Organization**: ユーザーストーリー（spec.mdのP1〜P5）単位でグループ化。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 並列実行可能（異なるファイル・依存なし）
- **[Story]**: 対応するユーザーストーリー（US1〜US5）

---

## Phase 1: Setup

- [ ] T001 `supabase/migrations/0002_supplier_contract_date.sql` を作成し、`public.suppliers` に `contract_started_at date` を追加する（data-model.md参照）
- [ ] T002 [P] `supabase/seed.sql` のサンプル仕入先データに `contract_started_at` の値を追加する

---

## Phase 2: Foundational (Blocking Prerequisites)

**⚠️ 全ユーザーストーリーはこのフェーズの完了後に着手する**

- [ ] T003 [P] `lib/core/models/master_data.dart` に `Variety` / `FarmField` / `Supplier` / `StorageLocation` エンティティ（`fromRow(Map<String, dynamic>)`ファクトリ付き）を作成する
- [ ] T004 [P] `lib/core/models/lot.dart` に `Lot` エンティティ・`LotOrigin` enum・`SizeGrade` enum（S/M/L/2L、`fromDb`/`label`、FR-016）を作成する
- [ ] T005 [P] `lib/core/models/shipment.dart` に `Shipment` エンティティ・`ShipmentChannel` enum（ec/wholesale/program）・`DeliveryMethod` enum（sagawa/direct/none）を作成する
- [ ] T006 [P] `lib/core/access/role_access.dart` に `bool canManageMasterData(UserRole role)` などの純粋関数を作成する（FR-003の権限判定を1箇所に集約）
- [ ] T007 [P] `lib/core/data/supabase_error_mapper.dart` に、Supabaseの例外（`PostgrestException`, `AuthException`, ネットワーク例外）を日本語の分かりやすいエラーメッセージ文字列に変換する関数を作成する（FR-018: オフライン等の保存失敗時のエラー表示に使う）
- [ ] T008 `lib/core/router/home_shell.dart` を `ConsumerWidget` 化し、`currentUserRoleProvider` を見て `canManageMasterData` が false の場合は「マスタ管理」ナビ項目を非表示にする
- [ ] T009 `lib/core/router/app_router.dart` の `redirect` に、`field_staff` が `/master-data` に直接アクセスした場合は `/` へリダイレクトする分岐を追加する（FR-003）

---

## Phase 3: User Story 1 - 基本データを準備してログインする (Priority: P1) 🎯 MVP

**Goal**: 管理者がマスタ（品種・圃場・仕入先・保管場所）を登録・編集でき、役割に応じて画面が出し分けられる。ログイン自体は実装済み。

**Independent Test**: 管理者でログインし品種を1件登録・保存できること、現場スタッフでログインした際にマスタ管理タブが表示されないことを確認する。

- [ ] T010 [P] [US1] `test/role_access_test.dart` に `canManageMasterData` のユニットテストを作成する（admin→true, field_staff→false）
- [ ] T011 [US1] `lib/features/master_data/data/master_data_repository.dart` に、`varieties`/`fields`/`suppliers`/`storage_locations` 各テーブルの一覧取得・新規作成メソッドを持つ `MasterDataRepository` を実装する（Supabaseアクセスはこのクラスに閉じ込める、Principle IV）
- [ ] T012 [US1] `lib/features/master_data/application/master_data_providers.dart` に、リポジトリのProviderと4種の一覧を取得する `FutureProvider` 群を実装する
- [ ] T013 [US1] `lib/features/master_data/presentation/master_data_screen.dart` を、4タブ（品種／圃場／仕入先／保管場所）のリスト表示＋追加ダイアログを持つ画面に実装する（`PlaceholderScreen`を置き換え）。仕入先タブは仕入先名・連絡先・住所・取引開始日を入力できるようにする（FR-001）
- [ ] T014 [US1] `lib/features/harvest` 等、他featureの品種/圃場/仕入先/保管場所の選択UIから `master_data_providers.dart` の一覧を再利用できるようにエクスポートを整理する

**Checkpoint**: US1は独立して動作確認可能（管理者のマスタ登録、役割別の画面出し分け）

---

## Phase 4: User Story 2 - 収穫・仕入れを記録する (Priority: P2)

**Goal**: 現場スタッフが収穫（自社栽培）・仕入れ（select提携先）を記録すると、`lots`テーブルに「冷蔵保管」ステータスのロットが作成される。

**Independent Test**: 収穫内容を1件入力・保存し、在庫一覧にそのロットが「冷蔵保管」として現れることを確認する。

- [ ] T015 [P] [US2] `test/size_grade_test.dart` に `SizeGrade` の日本語ラベル・DB値変換のユニットテストを作成する
- [ ] T016 [US2] `lib/features/harvest/data/harvest_repository.dart` に、収穫記録（`origin=own_farm`）と仕入れ記録（`origin=purchased`）それぞれを `lots` テーブルへINSERTするメソッドを実装する（FR-004, FR-005, FR-006）
- [ ] T017 [US2] `lib/features/harvest/application/harvest_providers.dart` にリポジトリProviderとフォーム送信状態（送信中/エラー）の`StateNotifier`または`AsyncNotifier`を実装する
- [ ] T018 [US2] `lib/features/harvest/presentation/harvest_screen.dart` を、「収穫」「仕入れ」を切り替えるセグメントと、圃場/品種/サイズ（チップ選択）・重量/個数/コンテナ数（ステッパー）を持つフォームに実装する（Principle II: 片手操作・チップ/ステッパー中心）。保存成功時はフォームをリセットして連続入力しやすくする（US2 Acceptance Scenario 3）
- [ ] T019 [US2] 保存失敗時に `supabase_error_mapper.dart` を使ったエラー表示を `harvest_screen.dart` に組み込む（FR-018）

**Checkpoint**: US1・US2が組み合わさり、マスタ登録→収穫/仕入れ記録の一連の流れが動作する

---

## Phase 5: User Story 3 - 在庫・追熟状況を確認し、必要なら訂正する (Priority: P3)

**Goal**: ロット一覧をステータスで絞り込んで確認でき、任意の状態に手動変更できる（誤操作の訂正を含む）。

**Independent Test**: あるロットを「追熟中」→「追熟済み」に変更し反映されること、誤って別の状態に変えたあと任意の状態へ訂正できることを確認する。

- [ ] T020 [US3] `lib/features/inventory/data/inventory_repository.dart` に、ロット一覧取得（ステータスでの絞り込み対応）・ステータス更新・`lot_status_history`取得のメソッドを実装する（FR-007, FR-008, FR-009, FR-010）
- [ ] T021 [US3] `lib/features/inventory/application/inventory_providers.dart` に、選択中フィルタの`StateProvider<LotStatus?>`と、それに連動する一覧`FutureProvider`を実装する
- [ ] T022 [US3] `lib/features/inventory/presentation/inventory_screen.dart` を、ステータス絞り込みチップ＋ロット一覧＋各ロットのステータス変更メニュー（現在の状態に関わらずどの状態にも変更可・FR-008）を持つ画面に実装する
- [ ] T023 [US3] `inventory_screen.dart` の各ロット詳細に、`lot_status_history` を新しい順に表示する簡易な履歴表示（ボトムシート等）を追加する（FR-009: 遡って確認できる）

**Checkpoint**: US1〜US3で「記録→在庫確認→訂正」の中心フローが完結する

---

## Phase 6: User Story 4 - 出荷を記録する (Priority: P4)

**Goal**: 出荷先種別（EC/卸売/体験プログラム）ごとに出荷記録を保存でき、在庫を超える数量の出荷はブロックされる。

**Independent Test**: 在庫のあるロットを選び出荷記録を保存して在庫一覧の数量が減ること、残り在庫を超える数量を入力すると保存がブロックされることを確認する。

- [ ] T024 [P] [US4] `test/shipment_validation_test.dart` に、出荷数量が残り在庫を超える／ちょうど／下回るケースの `validateShipmentQuantity` ユニットテストを作成する（FR-017）
- [ ] T025 [US4] `lib/core/validation/shipment_validation.dart` に `String? validateShipmentQuantity({required num requested, required num remaining})` を実装する（超過時はエラーメッセージ、それ以外は`null`を返す純粋関数）
- [ ] T026 [US4] `lib/features/shipping/data/shipping_repository.dart` に、対象ロットの残り在庫数量算出（ロット数量 − 既存出荷合計）と、出荷記録INSERT（保存前に`validateShipmentQuantity`を呼ぶ）を実装する
- [ ] T027 [US4] `lib/features/shipping/application/shipping_providers.dart` にリポジトリProviderと残数取得の`FutureProvider.family<num, String /*lotId*/>`を実装する
- [ ] T028 [US4] `lib/features/shipping/presentation/shipping_screen.dart` を、対象ロット選択・出荷先種別チップ（EC/卸売/体験プログラム）・数量ステッパー・配送方法（`channel=program`のときは非表示・FR-012）を持つフォームに実装し、バリデーションエラーをインライン表示する

**Checkpoint**: US1〜US4で在庫の増減が一通り記録できる

---

## Phase 7: User Story 5 - 在庫状況をひと目で把握する (Priority: P5)

**Goal**: ホーム画面に「追熟完了が近いロット」「在庫が少ない品種」が表示される。

**Independent Test**: 追熟完了間近のロットや在庫の少ない品種がある状態でホーム画面を開き、それらが一覧表示されることを確認する。

- [ ] T029 [P] [US5] `test/dashboard_metrics_test.dart` に、追熟完了が近いロットの判定・在庫僅少品種の判定のユニットテストを作成する
- [ ] T030 [US5] `lib/core/logic/dashboard_metrics.dart` に `List<Lot> lotsNearingRipeness(...)`（品種の標準追熟日数と`ripening_started_at`から残日数を計算）と `List<Variety> lowStockVarieties(...)`（品種ごとの在庫合計としきい値を比較）を実装する。しきい値は暫定値をコード上の定数として定義し、コメントでReFruitsとの確認が必要な旨を明記する（Principle IV）
- [ ] T031 [US5] `lib/features/dashboard/data/dashboard_repository.dart` に、全アクティブロットと品種一覧を取得するメソッドを実装する
- [ ] T032 [US5] `lib/features/dashboard/application/dashboard_providers.dart` に、T030の関数を適用した`FutureProvider`（近い追熟ロット・低在庫品種）を実装する
- [ ] T033 [US5] `lib/features/dashboard/presentation/dashboard_screen.dart` を、「追熟完了が近いロット」「在庫が少ない品種」の2セクションを表示する画面に実装する（FR-013, FR-014, SC-006）

**Checkpoint**: 全5ユーザーストーリーが完結し、spec.mdのAcceptance Scenariosをすべて満たす

---

## Phase 8: Polish & Cross-Cutting Concerns

- [ ] T034 [P] `flutter analyze` を実行し、警告0件を確認する（Principle V）
- [ ] T035 [P] `dart format lib test` を実行し、フォーマット崩れがないことを確認する（Principle V）
- [ ] T036 [P] `flutter test` を実行し、全ユニットテストが成功することを確認する
- [ ] T037 [P] `README.md` の「フォルダ構成」節を、プレースホルダーではなくなった各featureの実装内容に合わせて更新する
- [ ] T038 quickstart.md の検証シナリオ（US1〜US5）を実機/エミュレータで一通りなぞり、差異があればspec.md/tasks.mdにフィードバックする

---

## Dependencies & Execution Order

- Phase 1（Setup） → Phase 2（Foundational） → Phase 3〜7（US1〜US5、この順で優先度が高い）→ Phase 8（Polish）
- US1（マスタ管理）はUS2〜US5が参照する品種・圃場・仕入先・保管場所のデータ源であるため、実装順としても最優先とする
- US2〜US5はいずれもPhase 2完了後は独立して着手可能（同じ`lots`/`shipments`テーブルを参照するが、画面・リポジトリファイルが分かれているため並行開発できる）

## Parallel Execution Examples

- Phase 2: T003, T004, T005, T006, T007 は異なるファイルのため並列実行可能
- Phase 3〜7の各テストタスク（T010, T015, T024, T029）は、対応する実装タスクの前に並列で用意できる
- Phase 8: T034, T035, T036, T037 は並列実行可能

## Implementation Strategy

**MVP優先**: Phase 1〜3（Setup, Foundational, US1）を最初に完了させ、管理者がマスタを登録できる状態を最短で作る。その後US2（収穫・仕入れ記録）を実装した時点で、現場での最小限の記録運用は開始できる。US3〜US5は在庫の可視化・訂正・出荷の順で段階的に追加する。
