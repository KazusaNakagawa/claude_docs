# Claude Skills

Claude デスクトップアプリ (Cowork) 用のカスタムスキル集です。

## スキル一覧

### ワンショット（親スキル）

| スキル | 説明 | トリガー例 |
|--------|------|-----------|
| [req-full](./req-full/) | 以下3スキルをまとめてワンショット実行 | 「一式作って」「全部出して」 |

### 個別スキル（子スキル）

| スキル | 説明 | 出力 | トリガー例 |
|--------|------|------|-----------|
| [req-estimate](./req-estimate/) | 要件定義書から設計・工数見積もりを生成 | `customer-summary.md` `design-doc.md` | 「見積もって」「設計して」 |
| [db-design](./db-design/) | 設計書・要件書からDB設計書を生成 | `db-design.md` | 「DB設計して」「ER図作って」 |
| [req-investigate](./req-investigate/) | 不明点を調査し規約確認・ヒアリング事項を整理 | `investigation-report.md` | 「規約を調べて」「不明点まとめて」 |

### スキルの関係図

```
req-full（親・ワンショット）
├── req-estimate  → customer-summary.md + design-doc.md
├── db-design     → db-design.md
└── req-investigate → investigation-report.md
```

---

## ディレクトリ構成

```bash
skills/
├── README.md               # このファイル
├── install.sh              # .skill パッケージ生成スクリプト
├── dist/                   # ★ パッケージ済み .skill（git管理外）
│   ├── req-full.skill
│   ├── req-estimate.skill
│   ├── db-design.skill
│   └── req-investigate.skill
│
├── req-full/               # 親スキル（ワンショット）
│   └── SKILL.md
│
├── req-estimate/           # 設計書・工数見積もり
│   ├── SKILL.md            # ★ スキルの本体（プロンプト）
│   ├── references/
│   │   └── estimation-guide.md   # 工数見積もり参考資料
│   └── evals/
│       ├── evals.json
│       └── test-case-*.md
│
├── db-design/              # DB設計書
│   ├── SKILL.md
│   └── evals/
│       ├── evals.json
│       └── test-case-*.md
│
└── req-investigate/        # 規約調査・ヒアリング事項
    ├── SKILL.md
    └── evals/
        ├── evals.json
        └── test-case-*.md
```

---

## スキルの更新方法

### 1. SKILL.md を編集する

各スキルの本体は `SKILL.md` です。テキストエディタで直接編集できます。

```bash
# 例: req-estimate の手順を変更したい場合
open skills/req-estimate/SKILL.md
```

編集のポイント:
- `## Steps` セクション: スキルの実行手順
- `## Output Templates` セクション: 出力ドキュメントのテンプレート
- `## Quality Checklist` セクション: 完了条件

### 2. 参照資料を更新する

`references/` フォルダ内のファイルはスキルが参照する補足情報です。

```bash
# 工数見積もりの単価・バッファ率を変更したい場合
open skills/req-estimate/references/estimation-guide.md
```

### 3. テストケースを追加する

```bash
# 新しいテストケースを追加
cp skills/req-estimate/evals/test-case-1-simple-webapp.md \
   skills/req-estimate/evals/test-case-4-new-case.md

# evals.json にテストケースを追記
open skills/req-estimate/evals/evals.json
```

---

## スキルのインストール手順

編集後、Claude デスクトップアプリに反映するには `.skill` ファイルにパッケージして再インストールします。

```bash
# 全スキルを一括パッケージ
cd skills/
bash install.sh

# または個別にパッケージ
bash install.sh req-full
bash install.sh req-estimate
bash install.sh db-design
bash install.sh req-investigate
```

`dist/` に生成された `.skill` ファイルを Claude デスクトップアプリにドラッグ&ドロップしてインストールします。

> **初回インストール時の推奨順序**: `req-estimate` → `db-design` → `req-investigate` → `req-full`
> （req-full は子スキルを参照するため、子スキルを先にインストールしておく）

---

## Git 運用フロー

```bash
# スキルを更新したとき
git add skills/req-estimate/SKILL.md
git commit -m "fix: req-estimate - 工数バッファ率を修正"

# パッケージ → Claude アプリに再インストール
bash skills/install.sh req-estimate
# → dist/req-estimate.skill を Claude アプリにドラッグ&ドロップ

# 新しいスキルを追加したとき
mkdir -p skills/new-skill
# SKILL.md を作成 ...
git add skills/new-skill/
git commit -m "feat: add new-skill"
bash skills/install.sh new-skill
```

---

## スキル作成の参考資料

- SKILL.md の書き方: [skill-creator スキルのドキュメント](https://docs.claude.ai) を参照
- スキルの構成要素:
  - `name`: スキル名（英小文字・ハイフン区切り）
  - `description`: トリガー条件（どんな発言でこのスキルを使うか）
  - `steps`: 実行手順（番号付きリスト）
  - `output_templates`: 出力ドキュメントのひな形
