# Phase 1 Data Model: キウイ在庫管理 MVP

実装は `supabase/migrations/0001_init_mvp.sql` に既存。本ドキュメントはspec.mdのKey Entitiesと実スキーマの対応を明示し、`/speckit-clarify`で確定した内容との差分（要マイグレーション追加）を洗い出す。

## 品種 (`public.varieties`)

| フィールド | 型 | 説明 |
|---|---|---|
| id | uuid PK | |
| name | text unique | 品種名（例: 香緑、ヘイワード） |
| standard_ripening_days_min/max | int | 標準追熟日数の目安（ホーム画面「追熟完了が近いロット」判定に使用） |

- バリデーション: `name`は必須・一意。

## 圃場（区画） (`public.fields`)

| フィールド | 型 | 説明 |
|---|---|---|
| id | uuid PK | |
| name | text | 圃場名 |
| location | text | 所在地情報 |

## 仕入先 (`public.suppliers`)

| フィールド | 型 | 説明 |
|---|---|---|
| id | uuid PK | |
| name | text | 仕入先名 |
| location | text | 住所（既存カラムを住所として使用） |
| contact | text | 連絡先（電話番号 or メールアドレス） |
| **contract_started_at** | date, nullable | **取引開始日 — `/speckit-clarify`で追加確定。現行マイグレーションに未定義のため0001に列追加が必要** |

- バリデーション: `name`は必須。`contact`は電話番号またはメールアドレスの形式チェック（UIレベル、緩めのバリデーションでよい）。

## 保管場所 (`public.storage_locations`)

| フィールド | 型 | 説明 |
|---|---|---|
| id | uuid PK | |
| name | text | 倉庫・自宅保管など多様な場所を許容 |

## 在庫ロット (`public.lots`)

収穫（`own_farm`）と仕入れ（`purchased`）を1テーブルに統合（Principle V: シンプルさ優先）。

| フィールド | 型 | 説明 |
|---|---|---|
| id | uuid PK | |
| lot_code | text unique | 例: L-2609-01 |
| origin | enum(`own_farm`,`purchased`) | 収穫か仕入れか |
| variety_id | uuid FK → varieties | `origin = own_farm`のとき使用 |
| field_id | uuid FK → fields | `origin = own_farm`のとき使用 |
| supplier_id | uuid FK → suppliers | `origin = purchased`のとき使用 |
| harvested_or_purchased_at | date | 収穫日/仕入日 |
| weight_kg | numeric(10,2) | 重量 |
| quantity_count | int | 個数 |
| size_grade | text | **S/M/L/2Lの4区分に限定（`/speckit-clarify`で確定・FR-016）。UI側でChip選択、DBは当面text型のまま運用し、将来的にenum化を検討** |
| container_count | int | コンテナ数 |
| status | enum(`cold`,`ripening`,`ready`,`expired`) | 在庫ロットの状態（FR-007） |
| storage_location_id | uuid FK → storage_locations | |
| ripening_started_at / ripening_temperature_c / ripening_treatment_hours | timestamptz / numeric / numeric | 追熟の詳細（任意項目） |
| recorded_by | uuid FK → profiles | |

### 状態遷移（FR-008）

`cold → ripening → ready → expired` を基本順とするが、**FR-008により現在の状態に関わらずいずれの状態にも手動変更を許可する**（誤操作の訂正のため、遷移制約はDB/アプリ双方で設けない）。すべての変更は`lots`テーブルのUPDATEトリガー（`log_lot_status_change`）により`lot_status_history`に自動記録される（FR-009）。

### 出荷可能数量（FR-017）

`lots`自体に残数カラムは持たず、「残り在庫数量 = ロットの数量（weight_kg / quantity_count） − 当該ロットに紐づく`shipments`の合計数量」をアプリ側（リポジトリ層）で算出し、出荷記録の保存前にバリデーションする。

## ステータス変更履歴 (`public.lot_status_history`)

| フィールド | 型 | 説明 |
|---|---|---|
| id | uuid PK | |
| lot_id | uuid FK → lots | |
| from_status / to_status | enum(lot_status) nullable/not null | 変更前後の状態（FR-009） |
| changed_by | uuid FK → profiles | |
| changed_at | timestamptz | |
| note | text | 任意メモ |

- 生成規則: `lots`へのINSERT/UPDATEトリガーのみが書き込む。クライアントからの直接INSERTはRLSで禁止（トリガーは`security definer`のためRLSをバイパスして記録を継続）。

## 出荷記録 (`public.shipments`)

| フィールド | 型 | 説明 |
|---|---|---|
| id | uuid PK | |
| lot_id | uuid FK → lots | |
| channel | enum(`ec`,`wholesale`,`program`) | 出荷先の種類（FR-011） |
| customer_name | text | 任意 |
| quantity_kg | numeric(10,2) | 出荷数量（残り在庫を超えない値であること — FR-017） |
| delivery_method | enum(`sagawa`,`direct`,`none`) | `channel = program`の場合は`none`固定でUI上は非表示（FR-012） |
| shipped_at | date | 出荷日 |
| recorded_by | uuid FK → profiles | |

## ユーザー (`public.profiles`)

| フィールド | 型 | 説明 |
|---|---|---|
| id | uuid PK (= auth.users.id) | |
| full_name | text | |
| role | enum(`field_staff`,`admin`) | FR-003の2ロール |

- `auth.users`作成時にトリガー（`handle_new_user`）で自動生成。

## 必要なマイグレーション追加（tasks.mdで対応）

1. `suppliers`テーブルに`contract_started_at date`を追加する`0002_supplier_contract_date.sql`。
2. （任意）`shipments`保存時の残数チェックをDB制約/トリガーとしても二重化するか検討（アプリ側バリデーションを一次防御とし、必須ではない）。
