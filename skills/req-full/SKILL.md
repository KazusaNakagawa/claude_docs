---
name: req-full
description: |
  要件定義書（readme.md）を受け取り、req-estimate → db-design → detail-design → job-api-design → ops-monitoring → running-cost → proposal → req-investigate の8スキルをワンショットで順番に実行し、設計ドキュメント一式を生成する親スキル。
---

生成されるファイル:
- `01.customer-summary.md`     — 顧客向け対応可否サマリー・工数見積もり
- `02.design-doc.md`           — 実装者向け設計書（Mermaid アーキテクチャ図含む）
- `03.db-design.md`            — DB設計書（ER図・テーブル定義・AWS選定・Alembic方針）
- `04.detail-design.md`        — 詳細設計書（シーケンス図・API仕様・エラーハンドリング）
- `08.job-api-design.md`       — ジョブ処理API設計書（ジョブスキーマ・キュー・Worker・DLQ）※条件付き
- `09.ops-monitoring.md`       — 運用監視設計書（CloudWatch・Slack通知・SLO・アラート対応フロー）※条件付き
- `05.running-cost.md`         — 月額ランニング・運用保守・障害対応コスト・年間TCO
- `06.proposal.md`             — 経営者・意思決定者向け提案書（Ganttチャート・TCO含む）
- `07.investigation-report.md` — 規約調査・追加ヒアリング事項レポート

> ※ `08.job-api-design.md` と `09.ops-monitoring.md` は、設計に**非同期ジョブ処理（SQS / Lambda Worker / ECS Worker / バッチ処理）が含まれる場合のみ**生成する。

## Trigger Conditions
次のような状況で必ず使うこと:
- 「一式作って」「全部やって」「ワンショットで」
- 「req-full で」「設計ドキュメント全部欲しい」
- readme.md / 要件定義書を渡されて「これで全部出して」と言われたとき

---

## Steps

### Step 0: 子スキルの SKILL.md を読み込む

以下の順番で **Glob ツール** を使い、各子スキルの SKILL.md を検索して読み込む。
`**/スキル名/SKILL.md` パターンで検索し、見つかったパスに対して Read ツールで読み込む。

読み込む順番:

1. `req-estimate`  — `**/req-estimate/SKILL.md`
2. `db-design`     — `**/db-design/SKILL.md`
3. `detail-design` — `**/detail-design/SKILL.md`
4. `job-api-design` — `**/job-api-design/SKILL.md`
5. `ops-monitoring` — `**/ops-monitoring/SKILL.md`
6. `running-cost`  — `**/running-cost/SKILL.md`
7. `proposal`      — `**/proposal/SKILL.md`
8. `req-investigate` — `**/req-investigate/SKILL.md`

> ⚠️ いずれかのスキルが見つからない場合は、その旨と未実行スキル名をユーザーに伝え、
> 残りの見つかったスキルで処理を続行する（完了時に「生成できたファイルのみ」を報告）。

---

### Step 1: [req-estimate] 設計書・見積もりを生成する

読み込んだ `req-estimate` の SKILL.md の全ステップを実行する。

**入力**: ユーザーから渡された要件定義書
**出力**: 以下の2ファイルを要件書と同じフォルダに保存
- `01.customer-summary.md`
- `02.design-doc.md`

Step 1 が完了したら、生成した `02.design-doc.md` のパスを記憶しておく。

---

### Step 2: [db-design] DB設計書を生成する

読み込んだ `db-design` の SKILL.md の全ステップを実行する。

**入力**: Step 1 で生成した `02.design-doc.md`
**出力**: 以下のファイルを同じフォルダに保存
- `03.db-design.md`

---

### Step 3: [detail-design] 詳細設計書を生成する

読み込んだ `detail-design` の SKILL.md の全ステップを実行する。

**入力**: Step 1 の `02.design-doc.md` + Step 2 の `03.db-design.md`
**出力**: 同じフォルダに保存
- `04.detail-design.md`

---

### Step 4: [job-api-design] ジョブ処理 API 設計書を生成する（条件付き）

**実行条件の判断**: Step 1 の `02.design-doc.md` または元の要件定義書に以下のいずれかが含まれる場合のみ実行する。
- SQS / EventBridge / キュー の記述がある
- Lambda Worker / ECS Worker / バッチ処理 / 非同期ジョブ の記述がある
- 「ジョブ」「バッチ」「非同期」「スケジューラー」などのキーワードがある

**条件を満たさない場合**: このステップをスキップし、`08.job-api-design.md` は生成しない。その旨を完了サマリーに記載する。

読み込んだ `job-api-design` の SKILL.md の全ステップを実行する。

**入力**: Step 3 の `04.detail-design.md`（+ Step 1 の `02.design-doc.md` / Step 2 の `03.db-design.md`）
**出力**: 同じフォルダに保存
- `08.job-api-design.md`

---

### Step 5: [ops-monitoring] 運用監視設計書を生成する（条件付き）

**実行条件**: Step 4 で `08.job-api-design.md` が生成された場合のみ実行する。Step 4 をスキップした場合はこのステップもスキップする。

読み込んだ `ops-monitoring` の SKILL.md の全ステップを実行する。

**入力**: Step 4 の `08.job-api-design.md`（+ Step 3 の `04.detail-design.md`）
**出力**: 同じフォルダに保存
- `09.ops-monitoring.md`

---

### Step 6: [running-cost] 運用コストを算出する

読み込んだ `running-cost` の SKILL.md の全ステップを実行する。

**入力**: Step 1 の `02.design-doc.md`
**出力**: 同じフォルダに保存
- `05.running-cost.md`

---

### Step 7: [proposal] 提案書を生成する

読み込んだ `proposal` の SKILL.md の全ステップを実行する。

**入力**: Step 1 の `01.customer-summary.md` + Step 6 の `05.running-cost.md` + `02.design-doc.md`
**出力**: 同じフォルダに保存
- `06.proposal.md`

---

### Step 8: [req-investigate] 規約調査・ヒアリング事項をまとめる

読み込んだ `req-investigate` の SKILL.md の全ステップを実行する。

**入力**: Step 1 で生成した `02.design-doc.md`（および元の要件定義書）
**出力**: 同じフォルダに保存
- `07.investigation-report.md`

---

### Step 9: 完了サマリーを表示する

全スキルの実行が完了したら、以下の形式でユーザーに報告する:

```text
✅ req-full 完了 — {生成済みファイル数}ファイルを生成しました
⚠️ 未実行スキル: {未実行スキル名の一覧、または "なし"}

【顧客・意思決定者向け】
📋 06.proposal.md           — 提案書（TCO・スケジュール・Ganttチャート）
📄 01.customer-summary.md   — 技術サマリー・工数見積もり
💰 05.running-cost.md       — 月額ランニング・運用保守・障害対応コスト・年間TCO

【実装者向け】
📐 02.design-doc.md         — アーキテクチャ設計書
🗄️  03.db-design.md          — DB設計書（ER図）
🔧 04.detail-design.md      — 詳細設計書（シーケンス図・API仕様）
⚙️  08.job-api-design.md     — ジョブ処理API設計書（ジョブスキーマ・キュー・DLQ）※生成した場合のみ
📡 09.ops-monitoring.md     — 運用監視設計書（CloudWatch・Slack通知・アラート対応）※生成した場合のみ

【調査・確認事項】
🔍 07.investigation-report.md — 規約調査・ヒアリング事項

⚠️ 最優先確認事項: {investigation-report の 🔴 高優先度項目を箇条書き}
```

---

## Quality Checklist

全スキル完了後に確認:

- [ ] `01.customer-summary.md` に工数・フェーズ配分が含まれているか
- [ ] `02.design-doc.md` に Mermaid アーキテクチャ図があるか
- [ ] `03.db-design.md` に erDiagram と AWS 選定根拠があるか
- [ ] `04.detail-design.md` にシーケンス図と API 仕様があるか
- [ ] `05.running-cost.md` にAWSインフラ・運用保守・障害対応の3項目があるか
- [ ] `06.proposal.md` に Gantt チャート・3年間TCOがあるか
- [ ] `07.investigation-report.md` に 🔴🟡🟢 の優先度付きヒアリング事項があるか
- [ ] 実行対象となった全ファイルが同一フォルダに保存されているか
- [ ] `02.design-doc.md` のフロントエンド技術スタックに具体的なバージョンが明記されているか（WebSearch で確認した最新安定版を使用しているか）
- [ ] `02.design-doc.md` のバックエンド実行環境に具体的なバージョンが明記されているか（最新安定版を使用しているか）
- [ ] `03.db-design.md` の erDiagram に `FK UK` 複合指定がないか（構文エラー）。`FK` に統一し、UNIQUE はコメント文字列へ移動しているか
- [ ] 非同期ジョブ処理が含まれる場合: `08.job-api-design.md` にステータス遷移図（stateDiagram）・SQS キュー構成・Worker 設計・DLQ 手順があるか
- [ ] 非同期ジョブ処理が含まれる場合: `09.ops-monitoring.md` に日次チェック手順・DLQ 監視・SLO・アラート対応フロー・Slack 通知テンプレートがあるか
