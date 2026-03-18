---
name: ops-monitoring
description: |
  job-api-design.md や detail-design.md を受け取り、**AWS CloudWatch + Slack 通知を前提とした通常監視業務の運用設計書**（`ops-monitoring.md`）を生成するスキル。

  日次ヘルスチェック・DLQ 監視・SLO 確認・アラート対応フロー・Slack 通知テンプレートを網羅する。

  次のような状況で必ず使うこと:
  - 「監視設計をまとめて」「運用フローを整理して」「Slack 通知の設計をしたい」
  - 「DLQ の監視どうする？」「日次チェックの手順が欲しい」
  - job-api-design.md を渡されて「運用・監視部分を詳しく」と言われたとき
  - CloudWatch アラーム / SNS / Slack 連携の設計が必要なとき
  - リリース前に運用手順書を整備したいとき
---

# 通常監視業務 運用設計スキル

`job-api-design.md` または `detail-design.md` をもとに、AWS CloudWatch + Slack 通知を前提とした通常監視業務の運用設計書を生成します。

---

## Steps

### Step 1: 入力を読み込み、監視対象を洗い出す

以下の優先順でファイルを読み込む：
1. `job-api-design.md`（ジョブ処理設計 — SQS/Worker/DLQ 構成）
2. `detail-design.md`（API 設計 — エンドポイント / エラーハンドリング）
3. `design-doc.md`（アーキテクチャ全体）

以下を抽出する：
```text
- 監視対象コンポーネント（ECS / Lambda / SQS / RDS / API Gateway 等）
- 定義済みの SLO（処理時間 P95 / 完了率 / 開始遅延）
- DLQ の構成と保持期間
- 外部サービス依存（Claude API / メール / 決済 等）
- 既存のアラート定義（job-api-design の Step 9 があれば流用）
- Slack 通知先チャンネルの要件
```

---

### Step 2: 監視項目一覧を定義する

コンポーネントごとに監視項目・アラート閾値・通知先をまとめる。

**フォーマット**：

```text
| # | 監視対象 | メトリクス / 確認方法 | 閾値 / 異常条件 | 通知先 | 優先度 |
|---|---------|-------------------|--------------|-------|------|
| 1 | SQS 通常キュー | ApproximateNumberOfMessages | > {backlog上限} 件 | #alert-warning | Medium |
| 2 | SQS キュー滞留時間 | ApproximateAgeOfOldestMessage | > SLO秒数 | #alert-critical | High |
| 3 | DLQ | NumberOfMessagesSent | > 0 件 | #alert-critical | High |
| 4 | ECS Worker | CPUUtilization | > 85% (5分継続) | #alert-warning | Medium |
| 5 | ECS Worker | MemoryUtilization | > 90% (5分継続) | #alert-warning | Medium |
| 6 | ECS Worker タスク数 | RunningTaskCount | < 最小台数 | #alert-critical | High |
| 7 | Lambda エラー率 | Errors / Invocations | > 5% (1分) | #alert-critical | High |
| 8 | Lambda Duration (P95) | Duration P95 | > SLO秒数 × 1000ms | #alert-warning | Medium |
| 9 | RDS / Aurora | CPUUtilization | > 80% (10分継続) | #alert-warning | Medium |
| 10 | RDS / Aurora | FreeStorageSpace | < 20% | #alert-critical | High |
| 11 | API Gateway | 5XXError | > 1% (5分) | #alert-critical | High |
| 12 | API Gateway | Latency P99 | > SLO ms | #alert-warning | Medium |
| 13 | ジョブ完了率 (カスタム) | COMPLETED / (COMPLETED+DEAD) | < 99% (日次集計) | #alert-warning | Medium |
| 14 | DEAD ステータス蓄積 | jobs テーブル count | > 0 件 (日次) | #alert-warning | Medium |
| 15 | 外部 API 応答 | カスタムメトリクス (成功率) | < 95% (15分) | #alert-warning | Medium |
```

**優先度定義**：
- `High` : 即時対応（30分以内）、サービス影響あり / 見込まれる
- `Medium` : 営業時間内対応（当日中）、サービス影響なし / 軽微
- `Low` : 翌営業日確認、トレンド監視

---

### Step 3: 日次ヘルスチェック手順を定義する

毎営業日の始業時に実施する定常確認タスクをまとめる。

**チェックリスト形式（Slack 投稿用テンプレートと対応）**：

```markdown
## 日次ヘルスチェック（所要時間目安: 10〜15分）

### A. CloudWatch ダッシュボード確認（5分）
- [ ] SQS キュー深さが正常範囲（< {N} 件）であること
- [ ] DLQ のメッセージ数が 0 件であること
- [ ] 前日の Lambda / ECS エラー率が 1% 未満であること
- [ ] API Gateway 5xx エラーが 0 件（または許容範囲内）であること
- [ ] RDS / Aurora の CPU・ストレージが正常範囲であること

### B. ジョブ処理状況確認（5分）
- [ ] 前日の COMPLETED ジョブ数が期待値（{N}件/日）と大きく乖離していないこと
- [ ] DEAD ステータスのジョブが 0 件であること
  - 存在する場合 → job_id・error_message を Slack #alert-warning に投稿
- [ ] RUNNING のまま止まっているジョブ（> {タイムアウト時間}）がないこと
  ```sql
  SELECT job_id, job_type, status, started_at, NOW() - started_at AS elapsed
  FROM jobs
  WHERE status = 'RUNNING'
    AND started_at < NOW() - INTERVAL '{タイムアウト時間}';  -- 例: '1 hour', '30 minutes'
  ```

### C. SLO サマリー確認（3分）
- [ ] ジョブ開始遅延 P95 が SLO（< {N}秒）以内であること
- [ ] ジョブ処理時間 P95 が SLO（< {N}秒）以内であること
- [ ] ジョブ完了率が SLO（> 99.X%）以上であること
```

---

### Step 4: CloudWatch アラーム設計を定義する

Step 2 の監視項目を CloudWatch Alarm として実装するための設定値を定義する。

**アラーム設定フォーマット**：

```text
#### {アラーム名}

| 項目 | 値 |
|-----|---|
| メトリクス | {Namespace} / {MetricName} |
| ディメンション | {QueueName / FunctionName / etc.} |
| 統計 | Sum / Average / p95 |
| 評価期間 | {N} 分 × {M} 回連続 |
| 閾値 | {比較演算子} {値} |
| アクション (ALARM) | SNS → Slack #{channel} |
| アクション (OK) | SNS → Slack #{channel}（復旧通知） |
```

**重要アラームの定義例**：

```text
#### dlq-message-received

| 項目 | 値 |
|-----|---|
| メトリクス | AWS/SQS / NumberOfMessagesSent |
| ディメンション | QueueName: {system}-jobs-dlq |
| 統計 | Sum |
| 評価期間 | 1分 × 1回 |
| 閾値 | >= 1 |
| アクション (ALARM) | SNS → Slack #alert-critical |
| アクション (OK) | — (復旧通知不要) |

#### sqs-queue-depth-high

| 項目 | 値 |
|-----|---|
| メトリクス | AWS/SQS / ApproximateNumberOfMessages |
| ディメンション | QueueName: {system}-jobs-normal |
| 統計 | Average |
| 評価期間 | 5分 × 2回連続 |
| 閾値 | >= {backlog上限} |
| アクション (ALARM) | SNS → Slack #alert-warning |
| アクション (OK) | SNS → Slack #alert-warning（復旧通知） |

#### ecs-running-task-count-low

| 項目 | 値 |
|-----|---|
| メトリクス | ECS/ContainerInsights / RunningTaskCount |
| ディメンション | ClusterName / ServiceName |
| 統計 | Average |
| 評価期間 | 1分 × 2回連続 |
| 閾値 | < {最小タスク数} |
| アクション (ALARM) | SNS → Slack #alert-critical |
| アクション (OK) | SNS → Slack #alert-critical（復旧通知） |
```

---

### Step 5: SNS → Slack 通知連携設計を定義する

**通知チャンネル設計**：

| チャンネル名 | 用途 | 投稿されるアラーム | 対応優先度 |
|------------|------|----------------|---------|
| `#alert-critical` | 即時対応が必要なアラート | DLQ 着信 / タスク停止 / 5xx 急増 | High（30分以内） |
| `#alert-warning` | 当日中の確認が必要なアラート | キュー滞留 / CPU高騰 / 完了率低下 | Medium（営業時間内） |
| `#ops-daily` | 日次ヘルスチェック結果の投稿 | 手動投稿（後述テンプレート） | Low |

**SNS → Slack 連携方法**：

```text
方式: SNS Topic → Lambda（Slack Webhook 転送）または Chatbot（AWS Chatbot）

推奨: AWS Chatbot を使う場合
  - SNS Topic に Chatbot を subscribe
  - Chatbot の Slack 設定でチャンネルを紐付け
  - アラーム名のプレフィックスでルーティング（critical- / warning-）

Lambda 自前実装の場合:
  - SNS メッセージを受け取り Slack Incoming Webhook へ POST
  - アラーム状態（ALARM / OK）に応じてメッセージ色を変える（赤 / 緑）
```

**Slack 通知メッセージテンプレート**：

```text
【ALARM】🔴 {アラーム名}
- 状態: ALARM（{発生日時}）
- 内容: {メトリクス名} が {閾値} を超過（現在値: {現在値}）
- 対象: {リソース名}
- 対応: #alert-critical を参照し、対応フローに従ってください
- ダッシュボード: {CloudWatch Dashboard URL}

---

【OK】✅ {アラーム名}
- 状態: 復旧（{復旧日時}）
- 内容: {メトリクス名} が正常範囲に戻りました（現在値: {現在値}）
```

**日次ヘルスチェック Slack 投稿テンプレート（#ops-daily 用）**：

```text
【日次ヘルスチェック】{日付}

✅ SQS キュー: 正常（{現在のキュー深さ} 件）
✅ DLQ: 0 件
✅ DEAD ジョブ: 0 件
✅ ジョブ完了率（前日）: {XX.X}%
✅ API Gateway 5xx: {N} 件（{X}%）
✅ ECS Worker: {N} タスク稼働中

📊 ダッシュボード: {URL}
```

---

### Step 6: 週次・月次の定期確認タスクを定義する

**週次確認（毎週月曜）**：

```text
- [ ] 先週の DEAD ジョブ一覧を確認し、再発防止策が必要なものを ticket 化
- [ ] SLO 達成状況の週次サマリーを #ops-daily に投稿
      （開始遅延 P95 / 処理時間 P95 / 完了率 の週平均）
- [ ] CloudWatch アラーム発火回数のトレンドを確認
      （増加傾向なら調査・チューニングを検討）
- [ ] DLQ に残存メッセージがある場合は原因確認・リカバリ実施
```

**月次確認（月初第1営業日）**：

```text
- [ ] SLO 月次レポート作成（目標値 vs 実績値）
- [ ] CloudWatch ダッシュボードのメトリクス見直し
      （不要なアラームの整理 / 閾値の再調整）
- [ ] jobs テーブルのデータ量・インデックス効率の確認
      （ANALYZE / EXPLAIN で遅延クエリがないか）
- [ ] ログ保持期間・コストの確認
      （CloudWatch Logs の保持期間設定と料金）
- [ ] Worker / Lambda のメモリ・タイムアウト設定の最適化確認
```

---

### Step 7: 運用上の注意事項・FAQ を定義する

よくある誤検知・判断が迷いやすいケースをまとめる。

```text
#### Q. SQS キュー深さが急増したが、DEAD ジョブはない
→ Worker のスケールアウトが追いついていない可能性。
  ECS タスク数を確認し、Auto Scaling の設定（TargetTrackingScaling）を見直す。
  一時的なスパイクであれば問題なし（次の確認で解消されているか確認）。

#### Q. DLQ にメッセージが入ったが、ジョブ DB の status は COMPLETED になっている
→ SQS の DeleteMessage が失敗した後に DLQ へ移動した可能性。
  job_id で DB を確認し COMPLETED なら処理は完了しているため、
  DLQ メッセージは安全に削除して構わない。

#### Q. RUNNING のまま止まっているジョブがある
→ Worker のプロセスクラッシュまたはネットワーク断の可能性。
  ECS タスクログ / Lambda ログで該当 job_id を検索し、エラーを確認。
  手動で status を FAILED に更新後、POST /api/jobs/{id}/retry でリトライ。

#### Q. 外部 API（Claude API 等）の成功率が低下している
→ 外部サービス側の障害の可能性。ステータスページを確認する。
  Worker のリトライが連鎖してキュー深さが増加するため、
  必要に応じて Worker を一時停止（ECS タスク数 = 0）してキューを温存する。
```

---

### Step 8: ops-monitoring.md を出力する

---

## Output Template

### ops-monitoring.md

```markdown
# 通常監視業務 運用設計書 — {システム名}

**生成日**: {日付}
**対象**: 運用担当者向け
**前提**: job-api-design.md / detail-design.md を読んでいること
**監視基盤**: AWS CloudWatch + SNS + Slack

---

## 1. 監視項目一覧

{Step 2 の監視項目テーブル}

---

## 2. 日次ヘルスチェック手順

### 実施タイミング
毎営業日 始業後 30 分以内

### チェックリスト

#### A. CloudWatch ダッシュボード確認（5分）
{Step 3 の A セクション}

#### B. ジョブ処理状況確認（5分）
{Step 3 の B セクション}

#### C. SLO サマリー確認（3分）
{Step 3 の C セクション}

---

## 3. CloudWatch アラーム設計

{Step 4 の全アラーム定義}

---

## 4. SNS → Slack 通知連携設計

### 4-1. 通知チャンネル設計
{Step 5 のチャンネル設計表}

### 4-2. 連携方法
{Step 5 の SNS → Slack 連携方法}

### 4-3. Slack 通知メッセージテンプレート
{Step 5 の ALARM / OK テンプレート}

### 4-4. 日次ヘルスチェック投稿テンプレート
{Step 5 の #ops-daily テンプレート}

---

## 5. 週次・月次の定期確認タスク

### 5-1. 週次確認（毎週月曜）
{Step 6 の週次チェックリスト}

### 5-2. 月次確認（月初第1営業日）
{Step 6 の月次チェックリスト}

---

## 6. 運用上の注意事項・FAQ

{Step 7 の Q&A}

---

## 7. 関連リンク

| リソース | URL |
|--------|-----|
| CloudWatch ダッシュボード | {URL} |
| Slack #alert-critical | {channel link} |
| Slack #alert-warning | {channel link} |
| Slack #ops-daily | {channel link} |
| jobs テーブル（本番 DB） | {接続情報は Secrets Manager 参照} |
| SQS コンソール（DLQ） | {URL} |
```

---

## Quality Checklist

- [ ] 監視項目一覧に SQS・DLQ・ECS/Lambda・RDS・API Gateway が含まれているか
- [ ] 各監視項目に閾値・通知先・優先度が数値で記載されているか
- [ ] 日次チェックリストに DLQ 確認・DEAD ジョブ確認・RUNNING 滞留確認が含まれているか
- [ ] RUNNING 滞留確認の SQL が記載されているか
- [ ] SLO の数値（開始遅延 / 処理時間 P95 / 完了率）が埋められているか
- [ ] CloudWatch アラームに評価期間・連続回数・統計方式が定義されているか
- [ ] ALARM / OK 両方のアクション（SNS）が定義されているか
- [ ] Slack チャンネルが critical / warning / daily の 3 系統に分かれているか
- [ ] ALARM・OK・日次投稿の Slack メッセージテンプレートが含まれているか
- [ ] 週次・月次の定期確認タスクが含まれているか
- [ ] FAQ に「DLQ あり / DEAD なし」「RUNNING 滞留」「外部 API 低下」のケースが含まれているか

## 出力場所

生成したファイルはワークスペースフォルダに保存すること:
- `ops-monitoring.md`
