# Claude Code CLI パターン

Claude Code（CLI）でスキルをスラッシュコマンドとして使うための設定です。

## 設計思想：スキルの共通化

```
skills/<name>/SKILL.md  ← 単一ソース（ロジックの実体）
      ↑                         ↑
Cowork パターン           CLI パターン
(.skill パッケージ)       (スラッシュコマンド)
```

**SKILL.md を1箇所だけ更新すれば、Cowork・CLI 両方に反映されます。**

- Cowork: `install.sh` で `.skill` にパッケージ → デスクトップアプリにインストール
- CLI: `cli/install.sh` で `.claude/commands/` に展開 → Claude Code がスラッシュコマンドとして認識

`cli/commands/` 内のファイルは薄いラッパーです。実行時に Glob で `SKILL.md` を検索して読み込むため、ロジックの重複がありません。

---

## インストール手順

```bash
# claude_docs リポジトリのルートで実行
bash skills/cli/install.sh

# 特定プロジェクトにインストールする場合
bash skills/cli/install.sh /path/to/your-project

# 特定コマンドのみ
bash skills/cli/install.sh . req-full
```

インストール後、`.claude/commands/` に以下が展開されます:

```
.claude/commands/
├── req-full.md
├── req-estimate.md
├── db-design.md
├── detail-design.md
├── job-api-design.md
├── ops-monitoring.md
├── running-cost.md
├── proposal.md
└── req-investigate.md
```

---

## 使い方

Claude Code を `claude_docs/` ディレクトリで起動してスラッシュコマンドを入力します。

```bash
# claude_docs ディレクトリで Claude Code を起動
cd claude_docs
claude
```

### 一式まとめて生成（推奨）

```
/project:req-full README.md
```

要件定義書から設計ドキュメント一式（最大9ファイル）をワンショットで生成します。

### 個別に実行

| コマンド | 入力 | 出力 |
|---------|------|------|
| `/project:req-estimate README.md` | 要件定義書 | `01.customer-summary.md` `02.design-doc.md` |
| `/project:db-design 02.design-doc.md` | 設計書 | `03.db-design.md` |
| `/project:detail-design 02.design-doc.md` | 設計書 | `04.detail-design.md` |
| `/project:job-api-design 04.detail-design.md` | 詳細設計書 | `08.job-api-design.md` |
| `/project:ops-monitoring 08.job-api-design.md` | ジョブAPI設計書 | `09.ops-monitoring.md` |
| `/project:running-cost 02.design-doc.md` | 設計書 | `05.running-cost.md` |
| `/project:proposal 01.customer-summary.md` | 顧客サマリー | `06.proposal.md` |
| `/project:req-investigate 02.design-doc.md` | 設計書 | `07.investigation-report.md` |

> **出力先**: 入力ファイルと同じディレクトリに保存されます。

---

## ディレクトリ構成

```
cli/
├── README.md          # このファイル
├── install.sh         # .claude/commands/ に展開するスクリプト
└── commands/          # スラッシュコマンド定義（薄いラッパー）
    ├── req-full.md            ← **/req-full/SKILL.md を参照
    ├── req-estimate.md        ← **/req-estimate/SKILL.md を参照
    ├── db-design.md           ← **/db-design/SKILL.md を参照
    ├── detail-design.md       ← **/detail-design/SKILL.md を参照
    ├── job-api-design.md      ← **/job-api-design/SKILL.md を参照
    ├── ops-monitoring.md      ← **/ops-monitoring/SKILL.md を参照
    ├── running-cost.md        ← **/running-cost/SKILL.md を参照
    ├── proposal.md            ← **/proposal/SKILL.md を参照
    └── req-investigate.md     ← **/req-investigate/SKILL.md を参照
```

---

## スキルの更新フロー

```
1. skills/<name>/SKILL.md を編集（共通）
        ↓
2a. Cowork 向け: bash skills/install.sh <name>
    → dist/<name>.skill をデスクトップアプリに再インストール

2b. CLI 向け: bash skills/cli/install.sh
    → .claude/commands/ が自動更新（次回 Claude Code 起動時に反映）
```

Cowork パターンはパッケージの再インストールが必要ですが、CLI パターンは `SKILL.md` を直接参照するため **再インストール不要**（`claude` を再起動するだけ）。

---

## Cowork パターンとの比較

| 項目 | Cowork パターン | CLI パターン |
|------|---------------|-------------|
| 起動方法 | デスクトップアプリ + チャット | `claude` コマンド |
| スキル呼び出し | 自然言語でトリガー | `/project:<スキル名> <ファイル>` |
| SKILL.md の参照 | .skill パッケージに同梱 | 実行時に Glob で検索 |
| 更新後の反映 | .skill 再パッケージ＆再インストール | `claude` 再起動のみ |
| 向いている場面 | 非エンジニアへの共有・配布 | エンジニアの日常開発ワークフロー |
