# Claude Skills

Claude デスクトップアプリ (Cowork) 用のカスタムスキル集です。

## スキル一覧

### ワンショット（親スキル）

| スキル | 説明 | トリガー例 |
|--------|------|-----------|
| [req-full](./req-full/) | 以下子スキルをまとめてワンショット実行 | 「一式作って」「全部出して」 |

### 個別スキル（子スキル）

#### 上流工程（要件定義・提案）

| スキル | 対象 | 説明 | 出力 | トリガー例 |
|--------|------|------|------|-----------|
| [req-estimate](./req-estimate/) | 実装者 | 要件定義書から設計・工数見積もりを生成 | `01.customer-summary.md` `02.design-doc.md` | 「見積もって」「設計して」 |
| [req-investigate](./req-investigate/) | 実装者 | 不明点を調査し規約確認・ヒアリング事項を整理 | `07.investigation-report.md` | 「規約を調べて」「不明点まとめて」 |
| [running-cost](./running-cost/) | 顧客・経営者 | 月額AWS費用・運用保守・障害対応コスト・年間TCOを算出 | `05.running-cost.md` | 「ランニングコスト出して」「TCO計算して」 |
| [proposal](./proposal/) | 顧客・経営者 | 費用・Ganttチャート・TCO付きの意思決定向け提案書を生成 | `06.proposal.md` | 「提案書作って」「お客さんに見せる資料」 |

#### 詳細設計（実装者向け）

| スキル | 対象 | 説明 | 入力 | 出力 | トリガー例 |
|--------|------|------|------|------|-----------|
| [db-design](./db-design/) | 実装者 | 設計書・要件書からDB設計書を生成 | `02.design-doc.md` | `03.db-design.md` | 「DB設計して」「ER図作って」 |
| [detail-design](./detail-design/) | 実装者 | シーケンス図・API仕様・エラーハンドリングの詳細設計書を生成 | `02.design-doc.md` `03.db-design.md` | `04.detail-design.md` | 「詳細設計して」「API仕様まとめて」 |
| [job-api-design](./job-api-design/) | 実装者 | ジョブ処理・バッチ系APIのスキーマ/キュー/Worker/DLQ設計書を生成（非同期ジョブ処理がある場合のみ） | `04.detail-design.md` | `08.job-api-design.md` | 「ジョブ系APIの設計して」「SQS/Worker設計まとめて」 |

#### 運用設計（運用担当者向け）

| スキル | 対象 | 説明 | 入力 | 出力 | トリガー例 |
|--------|------|------|------|------|-----------|
| [ops-monitoring](./ops-monitoring/) | 運用担当者 | CloudWatch + Slack 通知を前提とした日次監視・DLQ確認・SLO管理の運用設計書を生成（job-api-design 実行時のみ） | `08.job-api-design.md` `04.detail-design.md` | `09.ops-monitoring.md` | 「監視設計して」「日次チェック手順まとめて」「Slack通知の設計」 |

### スキルの関係図

```text
req-full（親・ワンショット）
│
│  ── Step 1: 上流工程 ───────────────────────────────────────────────
├── req-estimate    → 01.customer-summary.md + 02.design-doc.md  （実装者向け）
│
│  ── Step 2〜3: 詳細設計 ─────────────────────────────────────────────
├── db-design       → 03.db-design.md       ← 02.design-doc.md
├── detail-design   → 04.detail-design.md   ← 02.design-doc.md + 03.db-design.md
│
│  ── Step 4〜5: ジョブ設計・監視設計（条件付き） ──────────────────────
├── job-api-design  → 08.job-api-design.md  ← 04.detail-design.md
│                     ※ 非同期ジョブ処理（SQS/Worker/バッチ）が含まれる場合のみ
├── ops-monitoring  → 09.ops-monitoring.md  ← 08.job-api-design.md
│                     ※ job-api-design が生成された場合のみ
│
│  ── Step 6〜8: コスト・提案・調査 ──────────────────────────────────
├── running-cost    → 05.running-cost.md    ← 02.design-doc.md
├── proposal        → 06.proposal.md        ← 01.customer-summary.md + 05.running-cost.md
└── req-investigate → 07.investigation-report.md ← 02.design-doc.md
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
│   ├── detail-design.skill
│   ├── job-api-design.skill
│   ├── running-cost.skill
│   ├── ops-monitoring.skill
│   ├── proposal.skill
│   └── req-investigate.skill
│
├── req-full/               # 親スキル（ワンショット・全スキル実行）
│   ├── SKILL.md
│   └── evals/              # 全7スキルの出力を網羅したサンプル
│
├── req-estimate/           # 設計書・工数見積もり（実装者向け）
│   ├── SKILL.md            # ★ スキルの本体（プロンプト）
│   ├── references/
│   │   └── estimation-guide.md   # 工数見積もり参考資料
│   └── evals/
│
├── db-design/              # DB設計書（実装者向け）
│   ├── SKILL.md
│   └── evals/
│
├── detail-design/          # 詳細設計書 シーケンス図・API仕様（実装者向け）
│   ├── SKILL.md
│   └── evals/
│
├── job-api-design/         # ジョブ処理API詳細設計 SQS/Worker/DLQ（実装者向け）
│   └── SKILL.md            # ※ evals なし（条件付き生成のため）
│
├── running-cost/           # 月額コスト・運用保守・障害対応・年間TCO（顧客・経営者向け）
│   ├── SKILL.md
│   └── evals/
│
├── proposal/               # 提案書 TCO・Ganttチャート（顧客・経営者向け）
│   ├── SKILL.md
│   └── evals/
│
├── req-investigate/        # 規約調査・ヒアリング事項
│   ├── SKILL.md
│   └── evals/
│
└── ops-monitoring/         # 通常監視業務 CloudWatch+Slack 日次チェック（運用担当者向け）
    └── SKILL.md             # ※ evals なし（条件付き生成のため）
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

スキルには **2つのインストールパターン**があります。詳細は [`cli/README.md`](./cli/README.md) を参照してください。

### Cowork パターン（Claude デスクトップアプリ）

編集後、Claude デスクトップアプリに反映するには `.skill` ファイルにパッケージして再インストールします。

```bash
# 全スキルを一括パッケージ（SKILL.md があるディレクトリを自動検出）
cd skills/
bash install.sh

# または個別にパッケージ
bash install.sh req-estimate
bash install.sh db-design
bash install.sh detail-design
bash install.sh job-api-design
bash install.sh ops-monitoring
bash install.sh proposal
bash install.sh req-investigate
bash install.sh req-full
```

`dist/` に生成された `.skill` ファイルを Claude デスクトップアプリにドラッグ&ドロップしてインストールします。

> **初回インストール時の推奨順序**:
>
> **req-full を使う場合**（依存スキルを先にインストール）:
> req-estimate → db-design → detail-design → job-api-design → ops-monitoring → running-cost → proposal → req-investigate → **req-full**
>
> **単体でも使用可能**:
> - `job-api-design` — 詳細設計フェーズで個別使用（req-full では非同期ジョブ処理がある場合のみ自動実行）
> - `ops-monitoring` — 運用設計フェーズで個別使用（req-full では job-api-design 実行時のみ自動実行）

---

## Git 運用フロー

```bash
# スキルを更新したとき
git add skills/req-estimate/SKILL.md
git commit -m "fix: req-estimate - 工数バッファ率を修正"

# [Cowork 向け] パッケージ → Claude アプリに再インストール
bash skills/install.sh req-estimate
# → dist/req-estimate.skill を Claude アプリにドラッグ&ドロップ

# [CLI 向け] .claude/commands/ を再展開（claude コマンド再起動で即反映）
bash skills/cli/install.sh

# 新しいスキルを追加したとき
mkdir -p skills/new-skill
# SKILL.md を作成 ...
git add skills/new-skill/
git commit -m "feat: add new-skill"
bash skills/install.sh new-skill
```

---

### CLI パターン（Claude Code）

Claude Code（ターミナル）でスラッシュコマンドとして使う場合:

```bash
# claude_docs リポジトリのルートで一括インストール
bash skills/cli/install.sh

# 特定プロジェクトにインストール
bash skills/cli/install.sh /path/to/your-project
```

インストール後は Claude Code で `/project:req-full README.md` のように呼び出せます。

---

## スキル作成の参考資料

- SKILL.md の書き方: [Claude Code スキルドキュメント](https://code.claude.com/docs/ja/skills) を参照
- スキルの構成要素:
  - `name`: スキル名（英小文字・ハイフン区切り）
  - `description`: トリガー条件（どんな発言でこのスキルを使うか）
  - `steps`: 実行手順（番号付きリスト）
  - `output_templates`: 出力ドキュメントのひな形
