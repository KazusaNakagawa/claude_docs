# req-full

## Description
要件定義書（readme.md）を受け取り、**req-estimate → db-design → req-investigate** の3スキルをワンショットで順番に実行し、設計ドキュメント一式を生成する親スキル。

生成されるファイル:
- `customer-summary.md` — 顧客向け対応可否サマリー・工数見積もり
- `design-doc.md` — 実装者向け設計書（Mermaid アーキテクチャ図含む）
- `db-design.md` — DB設計書（ER図・テーブル定義・AWS選定・Alembic方針）
- `investigation-report.md` — 規約調査・追加ヒアリング事項レポート

## Trigger Conditions
次のような状況で必ず使うこと:
- 「一式作って」「全部やって」「ワンショットで」
- 「req-full で」「設計ドキュメント全部欲しい」
- readme.md / 要件定義書を渡されて「これで全部出して」と言われたとき

---

## Steps

### Step 0: 子スキルの SKILL.md を読み込む

以下の順番で **Read ツール** を使い、各子スキルの SKILL.md を読み込む。
ファイルが見つからない場合は Glob で `**/SKILL.md` を検索して特定する。

読み込む順番と検索パス（上から順に試す）:

**① req-estimate**
```
/sessions/kind-sweet-cannon/mnt/.skills/skills/req-estimate/SKILL.md
/sessions/kind-sweet-cannon/mnt/claude_docs/skills/req-estimate/SKILL.md
```

**② db-design**
```
/sessions/kind-sweet-cannon/mnt/.skills/skills/db-design/SKILL.md
/sessions/kind-sweet-cannon/mnt/claude_docs/skills/db-design/SKILL.md
```

**③ req-investigate**
```
/sessions/kind-sweet-cannon/mnt/.skills/skills/req-investigate/SKILL.md
/sessions/kind-sweet-cannon/mnt/claude_docs/skills/req-investigate/SKILL.md
```

> ⚠️ いずれかのスキルが見つからない場合は、その旨をユーザーに伝え、
> 残りの見つかったスキルで処理を続行する。

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

### Step 3: [req-investigate] 規約調査・ヒアリング事項をまとめる

読み込んだ `req-investigate` の SKILL.md の全ステップを実行する。

**入力**: Step 1 で生成した `design-doc.md`（および元の要件定義書）
**出力**: 以下のファイルを同じフォルダに保存
- `investigation-report.md`

---

### Step 4: 完了サマリーを表示する

全スキルの実行が完了したら、以下の形式でユーザーに報告する:

```
✅ req-full 完了 — 4ファイルを生成しました

📄 customer-summary.md   — 顧客向け対応可否・工数サマリー
📐 design-doc.md         — 実装者向け設計書（アーキテクチャ図付き）
🗄️  db-design.md          — DB設計書（ER図・テーブル定義）
🔍 investigation-report.md — 規約調査・追加ヒアリング事項

⚠️ 重要リスク（あれば）: {investigation-report の 🔴 高優先度項目}
```

---

## Quality Checklist

全スキル完了後に確認:

- [ ] `customer-summary.md` に工数・フェーズ配分が含まれているか
- [ ] `design-doc.md` に Mermaid アーキテクチャ図があるか
- [ ] `db-design.md` に erDiagram と AWS選定根拠があるか
- [ ] `investigation-report.md` に 🔴🟡🟢 の優先度付きヒアリング事項があるか
- [ ] 4ファイルがすべて同一フォルダに保存されているか
