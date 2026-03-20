# req-full

## Description
要件定義書（readme.md）を受け取り、**req-estimate → db-design → detail-design → running-cost → proposal → req-investigate** の6スキルをワンショットで順番に実行し、設計ドキュメント一式を生成する親スキル。

生成されるファイル:
- `customer-summary.md`     — 顧客向け対応可否サマリー・工数見積もり
- `design-doc.md`           — 実装者向け設計書（Mermaid アーキテクチャ図含む）
- `db-design.md`            — DB設計書（ER図・テーブル定義・AWS選定・Alembic方針）
- `detail-design.md`        — 詳細設計書（シーケンス図・API仕様・エラーハンドリング）
- `running-cost.md`         — 月額ランニング・運用保守・障害対応コスト・年間TCO
- `proposal.md`             — 経営者・意思決定者向け提案書（Ganttチャート・TCO含む）
- `investigation-report.md` — 規約調査・追加ヒアリング事項レポート

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

1. `req-estimate` — `**/req-estimate/SKILL.md`
2. `db-design` — `**/db-design/SKILL.md`
3. `detail-design` — `**/detail-design/SKILL.md`
4. `running-cost` — `**/running-cost/SKILL.md`
5. `proposal` — `**/proposal/SKILL.md`
6. `req-investigate` — `**/req-investigate/SKILL.md`

> ⚠️ いずれかのスキルが見つからない場合は、その旨と未実行スキル名をユーザーに伝え、
> 残りの見つかったスキルで処理を続行する（完了時に「生成できたファイルのみ」を報告）。

---

### Step 1: [req-estimate] 設計書・見積もりを生成する

読み込んだ `req-estimate` の SKILL.md の全ステップを実行する。

**入力**: ユーザーから渡された要件定義書
**出力**: 以下の2ファイルを要件書と同じフォルダに保存
- `customer-summary.md`
- `design-doc.md`

Step 1 が完了したら、生成した `design-doc.md` のパスを記憶しておく。

---

### Step 2: [db-design] DB設計書を生成する

読み込んだ `db-design` の SKILL.md の全ステップを実行する。

**入力**: Step 1 で生成した `design-doc.md`
**出力**: 以下のファイルを同じフォルダに保存
- `db-design.md`

---

### Step 3: [detail-design] 詳細設計書を生成する

読み込んだ `detail-design` の SKILL.md の全ステップを実行する。

**入力**: Step 1 の `design-doc.md` + Step 2 の `db-design.md`
**出力**: 同じフォルダに保存
- `detail-design.md`

---

### Step 4: [running-cost] 運用コストを算出する

読み込んだ `running-cost` の SKILL.md の全ステップを実行する。

**入力**: Step 1 の `design-doc.md`
**出力**: 同じフォルダに保存
- `running-cost.md`

---

### Step 5: [proposal] 提案書を生成する

読み込んだ `proposal` の SKILL.md の全ステップを実行する。

**入力**: Step 1 の `customer-summary.md` + Step 4 の `running-cost.md` + `design-doc.md`
**出力**: 同じフォルダに保存
- `proposal.md`

---

### Step 6: [req-investigate] 規約調査・ヒアリング事項をまとめる

読み込んだ `req-investigate` の SKILL.md の全ステップを実行する。

**入力**: Step 1 で生成した `design-doc.md`（および元の要件定義書）
**出力**: 同じフォルダに保存
- `investigation-report.md`

---

### Step 7: 完了サマリーを表示する

全スキルの実行が完了したら、以下の形式でユーザーに報告する:

```text
✅ req-full 完了 — {生成済みファイル数}ファイルを生成しました
⚠️ 未実行スキル: {未実行スキル名の一覧、または "なし"}

【顧客・意思決定者向け】
📋 proposal.md           — 提案書（TCO・スケジュール・Ganttチャート）
📄 customer-summary.md   — 技術サマリー・工数見積もり
💰 running-cost.md       — 月額ランニング・運用保守・障害対応コスト・年間TCO

【実装者向け】
📐 design-doc.md         — アーキテクチャ設計書
🗄️  db-design.md          — DB設計書（ER図）
🔧 detail-design.md      — 詳細設計書（シーケンス図・API仕様）

【調査・確認事項】
🔍 investigation-report.md — 規約調査・ヒアリング事項

⚠️ 最優先確認事項: {investigation-report の 🔴 高優先度項目を箇条書き}
```

---

## Quality Checklist

全スキル完了後に確認:

- [ ] `proposal.md` に Gantt チャート・3年間TCOがあるか
- [ ] `running-cost.md` にAWSインフラ・運用保守・障害対応の3項目があるか
- [ ] `customer-summary.md` に工数・フェーズ配分が含まれているか
- [ ] `design-doc.md` に Mermaid アーキテクチャ図があるか
- [ ] `db-design.md` に erDiagram と AWS 選定根拠があるか
- [ ] `detail-design.md` にシーケンス図と API 仕様があるか
- [ ] `investigation-report.md` に 🔴🟡🟢 の優先度付きヒアリング事項があるか
- [ ] 実行対象となった全ファイルが同一フォルダに保存されているか
- [ ] `design-doc.md` のフロントエンド技術スタックに具体的なバージョンが明記されているか（WebSearch で確認した最新安定版を使用しているか）
- [ ] `db-design.md` の erDiagram に FK UK 複合指定（構文エラー）がないか
