---
name: job-api-design
description: |
  detail-design.md（または design-doc.md）を受け取り、**ジョブ処理・バッチ系 API に特化した詳細設計書**（`job-api-design.md`）を生成するスキル。

  ジョブスキーマ・キュー設計・ステータス管理・ワーカー設計・リトライ/DLQ・スケジューリング・モニタリングを網羅する。

  次のような状況で必ず使うこと:
  - 「ジョブ系APIの設計をまとめて」「バッチ処理の詳細設計が欲しい」
  - SQS / Lambda / ECS Worker のような非同期ジョブ構成が含まれるとき
  - 「ジョブのステータス管理をどう設計する？」「DLQ の設計を教えて」
  - ジョブスキーマ・ジョブキュー・ワーカー・スケジューラーが絡む設計書を作りたいとき
  - detail-design.md を渡されて「ジョブ処理部分をもっと詳しく」と言われたとき
---

# ジョブ処理 API 詳細設計スキル

`detail-design.md` または `design-doc.md` をもとに、ジョブ処理・バッチ系 API の詳細設計書を生成します。

---

## Steps

### Step 1: 入力を読み込み、ジョブ処理要素を抽出する

以下の優先順でファイルを読み込む：
1. `detail-design.md`（既存の詳細設計）
2. `design-doc.md`（アーキテクチャ設計）
3. `db-design.md`（テーブル設計）
4. 元の要件定義書 / readme.md

以下を抽出する：
```
- ジョブの種類・分類（どんな処理を非同期化するか）
- ジョブの起点（API呼び出し / スケジューラー / Webhook / ユーザー操作）
- キュー・メッセージブローカーの有無（SQS / EventBridge / 自前キュー等）
- ワーカーの実行環境（Lambda / ECS Fargate / EC2 等）
- 実行時間の見積もり（秒 / 分 / 時間オーダー）
- 冪等性が求められるかどうか
- 並行実行数・レートリミットの要件
- リトライ・失敗時の要件
- 外部サービス依存（Claude API / メール送信 / ファイルストレージ等）
```

---

### Step 2: ジョブスキーマを定義する

ジョブメッセージ（SQS や DB に格納するデータ）の構造を定義する。

**ジョブメッセージ共通フォーマット（SQS Body / DB jobs テーブル共通）**：
```json
{
  "job_id": "uuid-v4",
  "job_type": "{ジョブ種別識別子}",
  "version": "1.0",
  "payload": {
    // ジョブ種別ごとに定義（Step 2-2 参照）
  },
  "metadata": {
    "account_id": "uuid",
    "requested_by": "user_id or system",
    "created_at": "ISO8601",
    "scheduled_at": "ISO8601 or null",
    "priority": "high | normal | low"
  }
}
```

**ジョブ種別ごとのペイロード定義**：
要件から洗い出したジョブ種別ごとに、以下のフォーマットでペイロードを定義する。

```
#### {ジョブ種別名}（job_type: {識別子}）

| フィールド | 型 | 必須 | 説明 |
|-----------|---|------|------|
| target_id | string (uuid) | ✅ | 処理対象のリソースID |
| options   | object | ❌ | オプション設定 |
```

---

### Step 3: ジョブステータス管理を定義する

**ステータス遷移図（Mermaid）**：

```mermaid
stateDiagram-v2
    [*] --> PENDING : ジョブ登録
    PENDING --> QUEUED : キューへ送信
    QUEUED --> RUNNING : Worker取得
    RUNNING --> COMPLETED : 処理成功
    RUNNING --> FAILED : 処理失敗
    FAILED --> QUEUED : リトライ（上限未満）
    FAILED --> DEAD : リトライ上限超過 / DLQ移動
    RUNNING --> CANCELLED : キャンセル要求
    PENDING --> CANCELLED : キャンセル要求
```

**ステータス定義表**：

| ステータス | 説明 | 遷移元 | 遷移先 |
|-----------|------|-------|-------|
| PENDING | ジョブ登録済み、キュー未送信 | — | QUEUED / CANCELLED |
| QUEUED | キュー送信済み、Worker未取得 | PENDING / FAILED | RUNNING |
| RUNNING | Worker処理中 | QUEUED | COMPLETED / FAILED / CANCELLED |
| COMPLETED | 正常終了 | RUNNING | — |
| FAILED | 処理失敗（リトライ可能） | RUNNING | QUEUED / DEAD |
| DEAD | リトライ上限超過・恒久失敗 | FAILED | — |
| CANCELLED | キャンセル済み | PENDING / RUNNING | — |

**jobs テーブル設計（DB ステータス管理用）**：

```sql
CREATE TABLE jobs (
    job_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_type        VARCHAR(64) NOT NULL,
    status          VARCHAR(16) NOT NULL DEFAULT 'PENDING',
    payload         JSONB NOT NULL,
    metadata        JSONB NOT NULL DEFAULT '{}',
    priority        SMALLINT NOT NULL DEFAULT 5,  -- 1(高)〜10(低)
    retry_count     SMALLINT NOT NULL DEFAULT 0,
    max_retries     SMALLINT NOT NULL DEFAULT 3,
    error_message   TEXT,
    started_at      TIMESTAMPTZ,
    completed_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_jobs_status_priority ON jobs(status, priority, created_at);
CREATE INDEX idx_jobs_job_type ON jobs(job_type);
```

---

### Step 4: ジョブ API エンドポイントを定義する

ジョブの CRUD + 制御用 API エンドポイントを定義する。

**エンドポイント一覧テーブル**：

| メソッド | パス | 概要 | 認証 |
|---------|-----|------|------|
| POST | /api/jobs | ジョブ登録・キューイング | Bearer Token |
| GET | /api/jobs/{job_id} | ジョブ詳細取得（ステータス確認） | Bearer Token |
| GET | /api/jobs | ジョブ一覧取得（フィルタ・ページング） | Bearer Token |
| DELETE | /api/jobs/{job_id} | ジョブキャンセル | Bearer Token |
| POST | /api/jobs/{job_id}/retry | 手動リトライ | Bearer Token |
| GET | /api/jobs/{job_id}/logs | ジョブ実行ログ取得 | Bearer Token |

**各エンドポイント詳細フォーマット**：

```
### POST /api/jobs

**概要**: ジョブを登録し、キューに送信する
**認証**: Bearer Token

**リクエスト**:
| フィールド | 型 | 必須 | 説明 |
|-----------|---|------|------|
| job_type | string | ✅ | ジョブ種別識別子 |
| payload | object | ✅ | ジョブ種別に応じたペイロード |
| priority | string | ❌ | high / normal(default) / low |
| scheduled_at | string (ISO8601) | ❌ | スケジュール実行時刻（省略時即時） |

**レスポンス（202 Accepted）**:
| フィールド | 型 | 説明 |
|-----------|---|------|
| job_id | string (uuid) | 登録されたジョブID |
| status | string | 初期ステータス（PENDING or QUEUED） |
| created_at | string | 登録日時 |

**エラーレスポンス**:
| ステータス | エラーコード | 発生条件 |
|-----------|------------|---------|
| 400 | INVALID_JOB_TYPE | 未定義のジョブ種別 |
| 400 | VALIDATION_ERROR | ペイロードバリデーション失敗 |
| 429 | RATE_LIMIT_EXCEEDED | レートリミット超過 |
| 500 | QUEUE_ERROR | SQS送信失敗 |
```

（GET /api/jobs/{job_id}、DELETE、retry 等も同フォーマットで記載する）

---

### Step 5: キュー設計を定義する

**SQS キュー構成**：

| キュー名 | 種別 | 目的 | メッセージ保持期間 | 可視性タイムアウト |
|--------|-----|------|----------------|----------------|
| {system}-jobs-high.fifo | FIFO / 高優先度 | 優先度 high のジョブ | 4日 | {実行時間上限 × 1.5} 秒 |
| {system}-jobs-normal | Standard | 通常ジョブ | 4日 | {実行時間上限 × 1.5} 秒 |
| {system}-jobs-dlq | Standard | DLQ（失敗ジョブ） | 14日 | — |

**キュー設計の判断基準**：
- **FIFO vs Standard**: 処理順序保証が必要な場合は FIFO。スループット優先なら Standard
- **可視性タイムアウト**: Worker の最大処理時間 × 1.5 倍を設定（処理中に他 Worker が取得しないように）
- **優先度分離**: 高優先度ジョブ用キューを別途用意し、Worker の polling 順を制御する

**SQS → Worker メッセージフロー**：

```mermaid
sequenceDiagram
    participant API
    participant SQS as SQS Queue
    participant Worker as Worker (ECS/Lambda)
    participant DB
    participant DLQ as Dead Letter Queue

    API->>DB: INSERT jobs (status=PENDING)
    API->>SQS: SendMessage (job_id + payload)
    DB-->>API: OK
    SQS-->>API: MessageId
    API-->>Client: 202 Accepted {job_id}

    Worker->>SQS: ReceiveMessage (Long Polling)
    SQS-->>Worker: Message
    Worker->>DB: UPDATE status=RUNNING, started_at=NOW()
    Worker->>Worker: 処理実行

    alt 処理成功
        Worker->>DB: UPDATE status=COMPLETED, completed_at=NOW()
        Worker->>SQS: DeleteMessage
    else 処理失敗（リトライ上限未満）
        Worker->>DB: UPDATE status=FAILED, retry_count++, error_message
        Note over Worker,SQS: メッセージを削除しない → SQS が再配信
    else リトライ上限超過
        SQS->>DLQ: メッセージを DLQ へ移動
        Worker->>DB: UPDATE status=DEAD
    end
```

---

### Step 6: Worker 設計を定義する

**Worker 実行環境の選定基準**：

| 実行時間 | 同時実行数 | 推奨環境 | 理由 |
|--------|--------|--------|------|
| 〜15分 | 低〜中（〜1000/日） | Lambda | コスト最小、オートスケール |
| 〜60分 | 中〜高 | ECS Fargate (Task) | Lambda制限回避、メモリ確保 |
| 60分超 | 高 | ECS Fargate (Service + SQS Consumer) | 常駐Worker、スケーリング制御 |

**Worker 内部処理フロー**：

```
1. SQS から Long Polling でメッセージ取得（WaitTimeSeconds=20）
2. jobs テーブルを SELECT FOR UPDATE で status チェック（QUEUED → RUNNING へ更新）
3. 冪等性チェック（すでに COMPLETED / DEAD なら処理スキップ）
4. 処理の実行（ビジネスロジック）
5. 成功時: status=COMPLETED へ更新 → SQS メッセージ削除
6. 失敗時: status=FAILED へ更新（error_message を記録）→ メッセージを残す（SQS が再配信）
7. ハートビート更新（長時間処理の場合: 30秒ごとに updated_at を更新）
```

**冪等性の実装方針**：
- `job_id` を処理の一意キーとして扱う
- 処理開始前に DB で `status=RUNNING` へ原子的に更新（楽観ロックまたは `SELECT FOR UPDATE`）
- 外部サービス呼び出し（API、メール等）は `job_id` を冪等キーとして渡す

**並行実行制御**：

| 制御方法 | 実装箇所 | 設定値（目安） |
|--------|--------|------------|
| SQS MaxReceiveCount | SQS キュー設定 | 3〜5回（リトライ上限） |
| ECS タスク数上限 | ECS サービス設定 | 最大並行Worker数 |
| Lambda 同時実行上限 | Lambda 設定 | {peak TPS} × {avg duration} |
| レートリミット | API Gateway / アプリ層 | {要件値} req/sec per account |

---

### Step 7: リトライ・DLQ・エラーハンドリング方針を定義する

**リトライ設計**：

| エラー種別 | リトライ対象 | リトライ戦略 | 上限回数 |
|-----------|----------|-----------|--------|
| 外部 API 一時障害（5xx, timeout） | ✅ | 指数バックオフ（1s → 2s → 4s） | 3回 |
| バリデーションエラー（4xx） | ❌ | 即座に DEAD へ | — |
| DB 接続エラー | ✅ | 一定間隔（5秒）リトライ | 5回 |
| OOM / プロセスクラッシュ | ✅（SQS自動再配信） | SQS の可視性タイムアウト後に再配信 | MaxReceiveCount |

**DLQ 設計**：

```
- DLQ移動条件: SQS MaxReceiveCount（{N}回）を超過したメッセージ
- DLQ保持期間: 14日（調査・リカバリの余裕を確保）
- DLQ監視: CloudWatch Alarm（DLQ メッセージ数 > 0 で SNS → Slack 通知）
- 手動リカバリ手順:
  1. DLQ からメッセージ内容を確認（job_id / error_message）
  2. 原因調査・修正
  3. POST /api/jobs/{job_id}/retry API で再投入
  4. または SQS コンソールから通常キューへ redrive
```

**エラーレスポンス統一フォーマット（API）**：

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "人間が読めるエラーメッセージ",
    "details": [
      { "field": "payload.target_id", "message": "必須フィールドです" }
    ],
    "request_id": "req-uuid",
    "timestamp": "ISO8601"
  }
}
```

**Worker エラーログフォーマット（CloudWatch JSON）**：

```json
{
  "level": "ERROR",
  "job_id": "uuid",
  "job_type": "識別子",
  "retry_count": 2,
  "error_type": "ExternalAPIError",
  "error_message": "Claude API timeout after 30s",
  "stack_trace": "...",
  "duration_ms": 30124,
  "timestamp": "ISO8601"
}
```

---

### Step 8: スケジューリング設計を定義する（定期実行がある場合）

**スケジュール実行の方式**：

| 方式 | 使用サービス | 適用場面 |
|-----|-----------|--------|
| 時刻指定実行（Cron） | EventBridge Scheduler | 毎日/毎時の定期バッチ |
| 遅延実行（Delay） | SQS DelaySeconds / DB polling | N分後に実行 |
| 特定日時実行 | EventBridge Scheduler または jobs.scheduled_at | 予約送信等 |

**EventBridge Scheduler → SQS 連携（Cron ジョブ）**：

```mermaid
sequenceDiagram
    participant EB as EventBridge Scheduler
    participant SQS
    participant Worker
    participant DB

    EB->>SQS: スケジュール起動（Cron: 0 9 * * *）
    SQS-->>Worker: メッセージ受信
    Worker->>DB: INSERT jobs (job_type=DAILY_BATCH, status=RUNNING)
    Worker->>Worker: バッチ処理実行
    Worker->>DB: UPDATE status=COMPLETED
```

**スケジュール済みジョブの管理（DB polling 方式の場合）**：

```sql
-- scheduled_at を持つジョブを定期的にポーリングしてキューへ送信
SELECT * FROM jobs
WHERE status = 'PENDING'
  AND scheduled_at <= NOW()
ORDER BY priority ASC, scheduled_at ASC
LIMIT 100
FOR UPDATE SKIP LOCKED;
```

---

### Step 9: モニタリング・アラート設計を定義する

**CloudWatch メトリクス一覧**：

| メトリクス | 収集元 | アラート閾値（目安） | アクション |
|-----------|-------|----------------|--------|
| SQS ApproximateNumberOfMessages | SQS | > {backlog上限} | Slack通知 / Worker スケールアウト |
| SQS ApproximateAgeOfOldestMessage | SQS | > {SLO秒数} | PagerDuty / Slack 緊急通知 |
| DLQ NumberOfMessagesSent | SQS (DLQ) | > 0 | Slack通知（ジョブ失敗検知） |
| Worker エラー率 | Lambda / ECS カスタムメトリクス | > 5% | Slack通知 |
| ジョブ処理時間（P95） | カスタムメトリクス | > {SLO秒数} | Slack通知 |
| DEAD ステータスジョブ数 | DB / Lambda カスタムメトリクス | > 0 | Slack通知 |

**ダッシュボード構成（CloudWatch Dashboard）**：
- SQS キュー深さ（時系列グラフ）
- ジョブ処理数 / 時間（COMPLETED 件数推移）
- エラー率・DEAD 件数
- Worker CPU / メモリ使用率
- DLQ メッセージ数

**SLO 定義**（要件から設定する）：

| SLO 指標 | 目標値 | 計測方法 |
|---------|-------|--------|
| ジョブ開始遅延（QUEUED → RUNNING） | < {N} 秒 | jobs テーブルの started_at - created_at |
| ジョブ完了率（成功 / 全件） | > 99.X% | COMPLETED / (COMPLETED + DEAD) |
| P95 処理時間 | < {N} 秒 | completed_at - started_at の P95 |

---

### Step 10: 環境変数・設定値一覧を作成する

```
| 変数名 | 説明 | 設定箇所 | 例（ダミー） |
|--------|------|---------|------------|
| SQS_JOB_QUEUE_URL | 通常ジョブキューのURL | ECS 環境変数 | https://sqs.ap-northeast-1.amazonaws.com/123/jobs-normal |
| SQS_JOB_HIGH_QUEUE_URL | 高優先度キューのURL | ECS 環境変数 | https://sqs.ap-northeast-1.amazonaws.com/123/jobs-high.fifo |
| SQS_DLQ_URL | DLQ の URL（監視用） | ECS 環境変数 | https://sqs.ap-northeast-1.amazonaws.com/123/jobs-dlq |
| WORKER_CONCURRENCY | 1 Worker あたりの同時処理数 | ECS 環境変数 | 5 |
| JOB_VISIBILITY_TIMEOUT | SQS 可視性タイムアウト（秒） | SSM Parameter Store | 300 |
| JOB_MAX_RETRIES | リトライ上限回数 | SSM Parameter Store | 3 |
| EXTERNAL_API_TIMEOUT | 外部API呼び出しタイムアウト（秒） | SSM Parameter Store | 30 |
| RATE_LIMIT_PER_ACCOUNT | アカウントあたりのレートリミット（req/min） | SSM Parameter Store | 60 |
| DATABASE_URL | Aurora 接続文字列 | Secrets Manager | postgresql://user:pass@host/db |
```

---

### Step 11: job-api-design.md を出力する

---

## Output Template

### job-api-design.md

```markdown
# ジョブ処理 API 詳細設計書 — {システム名}

**生成日**: {日付}
**対象**: 実装担当者向け
**前提**: design-doc.md / detail-design.md を読んでいること

---

## 1. ジョブ種別一覧

| job_type | 説明 | 起点 | 実行時間目安 | 冪等性 |
|---------|------|-----|-----------|------|
{ジョブ種別の一覧表}

---

## 2. ジョブスキーマ定義

### 2-1. 共通メッセージフォーマット
{Step 2 の共通フォーマット}

### 2-2. ジョブ種別別ペイロード
{Step 2 のジョブ種別ごとのペイロード定義}

---

## 3. ジョブステータス管理

### 3-1. ステータス遷移図
{Step 3 の stateDiagram}

### 3-2. ステータス定義表
{Step 3 のステータス定義表}

### 3-3. jobs テーブル設計
{Step 3 の DDL}

---

## 4. ジョブ API エンドポイント

### 4-1. エンドポイント一覧
{Step 4 のエンドポイント一覧}

### 4-2. エンドポイント詳細
{Step 4 の各エンドポイント詳細}

---

## 5. キュー設計

### 5-1. SQS キュー構成
{Step 5 のキュー構成表}

### 5-2. キュー設計の判断基準
{Step 5 の判断基準}

### 5-3. SQS → Worker フローシーケンス図
{Step 5 の sequenceDiagram}

---

## 6. Worker 設計

### 6-1. 実行環境選定
{Step 6 の環境選定表}

### 6-2. Worker 内部処理フロー
{Step 6 の処理フロー}

### 6-3. 冪等性の実装方針
{Step 6 の冪等性方針}

### 6-4. 並行実行制御
{Step 6 の並行実行表}

---

## 7. リトライ・DLQ・エラーハンドリング

### 7-1. リトライ設計
{Step 7 のリトライ設計表}

### 7-2. DLQ 設計
{Step 7 の DLQ 設計}

### 7-3. エラーレスポンス統一フォーマット
{Step 7 の API エラーフォーマット}

### 7-4. Worker エラーログフォーマット
{Step 7 のログフォーマット}

---

## 8. スケジューリング設計

{Step 8 の内容（スケジュール実行がある場合のみ）}

---

## 9. モニタリング・アラート設計

### 9-1. CloudWatch メトリクス一覧
{Step 9 のメトリクス表}

### 9-2. ダッシュボード構成
{Step 9 のダッシュボード構成}

### 9-3. SLO 定義
{Step 9 の SLO 定義表}

---

## 10. 環境変数・設定値一覧

{Step 10 の環境変数表}

---

## 11. 実装上の注意事項

- {冪等性実装の落とし穴（例: 外部API呼び出しの重複実行防止）}
- {可視性タイムアウトのチューニング注意事項}
- {FIFO キューの MessageGroupId 設計}
- {Worker クラッシュ時のメッセージ再配信タイミング}
```

---

## Quality Checklist

- [ ] ジョブ種別一覧にすべての非同期処理が網羅されているか
- [ ] ジョブスキーマに job_id・job_type・payload・metadata が含まれているか
- [ ] ステータス遷移図（stateDiagram）が含まれているか
- [ ] jobs テーブルの DDL が記載されているか（status カラム・インデックス含む）
- [ ] API エンドポイントに POST /api/jobs・GET /api/jobs/{id}・DELETE・retry が含まれているか
- [ ] SQS キュー構成（通常キュー・高優先キュー・DLQ）が定義されているか
- [ ] 可視性タイムアウトの設定値と根拠が記載されているか
- [ ] Worker 実行環境の選定理由が記載されているか
- [ ] 冪等性の実装方針が具体的に記載されているか
- [ ] リトライ設計にエラー種別ごとの方針（対象 / 非対象）が含まれているか
- [ ] DLQ の保持期間・監視・手動リカバリ手順が記載されているか
- [ ] エラーログが JSON 構造化ログ形式で定義されているか
- [ ] CloudWatch アラート（DLQ・キュー深さ・処理遅延）が定義されているか
- [ ] SLO（開始遅延・完了率・処理時間 P95）が数値で定義されているか
- [ ] 環境変数一覧にキューURL・タイムアウト値・リトライ回数が含まれているか

## 出力場所

生成したファイルはワークスペースフォルダに保存すること:
- `job-api-design.md`
