---
name: req-full
description: 要件定義書を受け取り、req-estimate・db-design・detail-design・running-cost・proposal・req-investigate の全スキルをワンショットで実行して設計ドキュメント一式（最大9ファイル）を生成する
---

# req-full — 設計ドキュメント一式ワンショット生成

**使い方**: `/project:req-full <要件定義書のパス>`
**例**: `/project:req-full README.md`

入力ファイル: $ARGUMENTS

---

## 概要

要件定義書から、設計ドキュメント一式（最大9ファイル）をワンショットで生成します。

生成されるファイル:
- `01.customer-summary.md`     — 顧客向け対応可否サマリー・工数見積もり
- `02.design-doc.md`           — 実装者向け設計書（Mermaid アーキテクチャ図含む）
- `03.db-design.md`            — DB設計書（ER図・テーブル定義・AWS選定）
- `04.detail-design.md`        — 詳細設計書（シーケンス図・API仕様）
- `08.job-api-design.md`       — ジョブ処理API設計書 ※非同期処理がある場合のみ
- `09.ops-monitoring.md`       — 運用監視設計書 ※job-api-design 生成時のみ
- `05.running-cost.md`         — 月額ランニング・年間TCO
- `06.proposal.md`             — 経営者向け提案書（Ganttチャート・TCO）
- `07.investigation-report.md` — 規約調査・ヒアリング事項レポート

---

## 実行手順

### Step 0: 子スキルの SKILL.md を読み込む

以下を **Glob ツール**で検索し、見つかったパスを **Read ツール**で順番に読み込む:

1. `**/req-estimate/SKILL.md`
2. `**/db-design/SKILL.md`
3. `**/detail-design/SKILL.md`
4. `**/job-api-design/SKILL.md`
5. `**/ops-monitoring/SKILL.md`
6. `**/running-cost/SKILL.md`
7. `**/proposal/SKILL.md`
8. `**/req-investigate/SKILL.md`

> ⚠️ いずれかのスキルが見つからない場合は、その旨と未実行スキル名をユーザーに伝え、残りのスキルで処理を続行する。

---

### Step 1〜9: 各スキルを順番に実行する

**共通ルール（全ステップ）**:
- **入力ファイル**: `$ARGUMENTS` で指定されたファイル（または前ステップの出力ファイル）
- **出力先**: `$ARGUMENTS` のファイルが存在するディレクトリ
  - 例: `$ARGUMENTS` が `path/to/README.md` なら `path/to/` に全ファイルを出力する
  - ※ 各 SKILL.md に「ワークスペースフォルダに保存」と書かれている場合も、この出力先ルールを優先する

**Step 1: [req-estimate]**
- 入力: `$ARGUMENTS`（要件定義書）
- 出力: `01.customer-summary.md`、`02.design-doc.md`

**Step 2: [db-design]**
- 入力: Step 1 の `02.design-doc.md`
- 出力: `03.db-design.md`

**Step 3: [detail-design]**
- 入力: `02.design-doc.md` + `03.db-design.md`
- 出力: `04.detail-design.md`

**Step 4: [job-api-design]（条件付き）**
- 実行条件: 要件定義書または `02.design-doc.md` に SQS / Lambda Worker / ECS Worker / バッチ処理 / 非同期ジョブ の記述がある場合のみ
- 入力: `04.detail-design.md`
- 出力: `08.job-api-design.md`（条件を満たさない場合はスキップ）

**Step 5: [ops-monitoring]（条件付き）**
- 実行条件: Step 4 で `08.job-api-design.md` が生成された場合のみ
- 入力: `08.job-api-design.md` + `04.detail-design.md`
- 出力: `09.ops-monitoring.md`

**Step 6: [running-cost]**
- 入力: `02.design-doc.md`
- 出力: `05.running-cost.md`

**Step 7: [proposal]**
- 入力: `01.customer-summary.md` + `05.running-cost.md` + `02.design-doc.md`
- 出力: `06.proposal.md`

**Step 8: [req-investigate]**
- 入力: `02.design-doc.md`（+ 元の要件定義書）
- 出力: `07.investigation-report.md`

---

### Step 9: 完了サマリーを表示する

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
⚙️  08.job-api-design.md     — ジョブ処理API設計書 ※生成した場合のみ
📡 09.ops-monitoring.md     — 運用監視設計書 ※生成した場合のみ

【調査・確認事項】
🔍 07.investigation-report.md — 規約調査・ヒアリング事項

⚠️ 最優先確認事項: {investigation-report の 🔴 高優先度項目を箇条書き}
```
