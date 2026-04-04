# Claude Code CLI パターン

Claude Code（CLI）でスキルをスラッシュコマンドとして使うための設定です。

## 設計思想：スキルの共通化

```bash
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

### ✅ 推奨：ユーザーグローバル（どのプロジェクトからでも使える）

```bash
# claude_docs リポジトリのルートで実行
bash skills/cli/install.sh --global
```

`~/.claude/commands/` に展開され、**どのプロジェクトでも** `claude` を起動すればすぐ使えます。コマンドは `/<name>` で呼び出します。

```text
/req-full README.md
/req-estimate README.md
```

### プロジェクトローカル（このプロジェクト内でのみ使う）

```bash
# claude_docs ディレクトリのルートで実行
bash skills/cli/install.sh

# 特定コマンドのみ
bash skills/cli/install.sh . req-full
```

`claude_docs/.claude/commands/` に展開されます。`claude_docs/` ディレクトリで `claude` を起動したときのみ有効です。コマンドは `/project:<name>` で呼び出します。

```text
/project:req-full README.md
```

---

## 使い方

```bash
# 任意のディレクトリで Claude Code を起動（グローバルインストール済みの場合）
claude

# または claude_docs/ ディレクトリで起動（ローカルインストールの場合）
cd ~/work/claude_docs
claude
```

### 一式まとめて生成（推奨）

```text
# グローバルの場合
/req-full README.md

# プロジェクトローカルの場合
/project:req-full README.md
```

要件定義書から設計ドキュメント一式（最大9ファイル）をワンショットで生成します。

### 個別に実行

| コマンド（グローバル） | 入力 | 出力 |
|---------|------|------|
| `/req-estimate README.md` | 要件定義書 | `01.customer-summary.md` `02.design-doc.md` |
| `/db-design 02.design-doc.md` | 設計書 | `03.db-design.md` |
| `/detail-design 02.design-doc.md` | 設計書 | `04.detail-design.md` |
| `/job-api-design 04.detail-design.md` | 詳細設計書 | `08.job-api-design.md` |
| `/ops-monitoring 08.job-api-design.md` | ジョブAPI設計書 | `09.ops-monitoring.md` |
| `/running-cost 02.design-doc.md` | 設計書 | `05.running-cost.md` |
| `/proposal 01.customer-summary.md` | 顧客サマリー | `06.proposal.md` |
| `/req-investigate 02.design-doc.md` | 設計書 | `07.investigation-report.md` |

#### 開発ユーティリティ（任意のプロジェクトで使用可能）

| コマンド（グローバル） | 説明 |
|---------|------|
| `/repo-investigate` | 構造・依存関係・エントリーポイントを調査 |
| `/repo-investigate src/` | 指定パスを調査 |
| `/repo-investigate-design` | API設計・データフロー・Mermaid図（アーキテクチャ図・シーケンス図）・横断的調査（テスト/セキュリティ/CI/CD等）を日本語で生成 |
| `/repo-investigate-full` | `repo-investigate` + `repo-investigate-design` をワンショット実行し2レポートを生成 |

> プロジェクトローカルの場合は `/` の後に `project:` を付けてください（例: `/project:req-full`）。
> **出力先**: 入力ファイルと同じディレクトリに保存されます。

---

## ディレクトリ構成

```text
cli/
├── README.md          # このファイル
├── install.sh         # .claude/commands/ に展開するスクリプト
└── commands/          # スラッシュコマンド定義
    ├── req-full.md            ← `**/req-full/SKILL.md` を参照（薄いラッパー）
    ├── req-estimate.md        ← `**/req-estimate/SKILL.md` を参照（薄いラッパー）
    ├── db-design.md           ← `**/db-design/SKILL.md` を参照（薄いラッパー）
    ├── detail-design.md       ← `**/detail-design/SKILL.md` を参照（薄いラッパー）
    ├── job-api-design.md      ← `**/job-api-design/SKILL.md` を参照（薄いラッパー）
    ├── ops-monitoring.md      ← `**/ops-monitoring/SKILL.md` を参照（薄いラッパー）
    ├── running-cost.md        ← `**/running-cost/SKILL.md` を参照（薄いラッパー）
    ├── proposal.md            ← `**/proposal/SKILL.md` を参照（薄いラッパー）
    ├── req-investigate.md     ← `**/req-investigate/SKILL.md` を参照（薄いラッパー）
    ├── repo-investigate.md          ← 自己完結型（任意プロジェクトで動作）
    ├── repo-investigate-design.md  ← 自己完結型（任意プロジェクトで動作）
    └── repo-investigate-full.md    ← 自己完結型（任意プロジェクトで動作）
```

> **薄いラッパー vs 自己完結型**
>
> - **薄いラッパー**: 実行時に Glob で `SKILL.md` を検索して読み込む。`claude_docs/` を含むディレクトリで実行する必要がある。
> - **自己完結型** (`repo-investigate`, `repo-investigate-design`, `repo-investigate-full`): 全内容をコマンドファイルに埋め込み済み。グローバルインストールで **任意のプロジェクトから** 実行可能。

---

## スキルの更新フロー

**既存スキルを編集する場合:**

```text
1. skills/<name>/SKILL.md を編集
        ↓
2a. Cowork 向け: bash skills/install.sh <name>
    → dist/<name>.skill をデスクトップアプリに再インストール

2b. CLI 向け: claude を再起動するだけ（install.sh 不要）
    → 実行時に Glob で SKILL.md を参照するため、再インストール不要
```

**新しいスキル（コマンド）を追加する場合:**

```text
1. skills/<name>/SKILL.md を作成
2. skills/cli/commands/<name>.md を作成（薄いラッパー）
        ↓
3a. Cowork 向け: bash skills/install.sh <name>
3b. CLI 向け: bash skills/cli/install.sh
    → .claude/commands/<name>.md が展開され、コマンドとして登録される
    → claude を再起動して反映
```

Cowork パターンはパッケージの再インストールが必要ですが、CLI パターンは既存 `SKILL.md` 編集時は **再インストール不要**（`claude` を再起動するだけ）。新コマンド追加時のみ `install.sh` の実行が必要です。

---

## Cowork パターンとの比較

| 項目 | Cowork パターン | CLI パターン |
|------|---------------|-------------|
| 起動方法 | デスクトップアプリ + チャット | `claude` コマンド |
| スキル呼び出し | 自然言語でトリガー | `/project:<スキル名> <ファイル>` |
| SKILL.md の参照 | .skill パッケージに同梱 | 実行時に Glob で検索 |
| 更新後の反映 | .skill 再パッケージ＆再インストール | `claude` 再起動のみ |
| 向いている場面 | 非エンジニアへの共有・配布 | エンジニアの日常開発ワークフロー |
