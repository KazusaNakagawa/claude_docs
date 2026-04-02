# claude_docs

Claude で試した内容をナレッジとして残すためのリポジトリです。

---

## ディレクトリ構成

```bash
claude_docs/
├── .claude/         # Claude Code 用設定・スキル
│   ├── settings.json.example
│   └── skills/      # Claude Code 向けスキル（開発作業補助系）
│
└── skills/          # Claude カスタムスキル集（設計支援系）
    ├── README.md    # スキル一覧・使い方・インストール手順
    ├── install.sh   # Cowork 向け .skill パッケージ生成スクリプト
    ├── cli/         # Claude Code（CLI）向けスラッシュコマンド
    ├── req-full/    # 親スキル（以下8スキルをワンショット実行）
    ├── req-estimate/
    ├── db-design/
    ├── detail-design/
    ├── job-api-design/
    ├── ops-monitoring/
    ├── running-cost/
    ├── proposal/
    └── req-investigate/
```

各スキルの詳細・インストール手順は [`skills/README.md`](./skills/README.md) を参照してください。

---

## .claude/skills/ — 開発作業補助スキル

Claude Code での開発作業を補助するスキルを格納しています。

| スキル | 説明 |
| --- | --- |
| `parallel-setup` | tmux + git worktree を使った並列開発環境を構築する |
| `parallel-cleanup` | 並列開発環境（worktree・tmux セッション）を解体する |
| `review-fix` | PR のレビューフィードバックを確認・修正・プッシュする |
| `start` | GitHub Issue を起点として開発を開始する |

---

## skills/ — 設計支援スキル

要件定義から提案書まで一式を生成するスキル群です。サンプル出力は各スキルの `evals/expected-outputs/` に格納しています。

| スキル | 説明 |
| --- | --- |
| `req-full` | 以下8スキルをワンショット実行する親スキル |
| `req-estimate` | 要件定義書から設計書・工数見積もりを生成 |
| `db-design` | DB設計書（ER図・テーブル定義）を生成 |
| `detail-design` | 詳細設計書（シーケンス図・API仕様）を生成 |
| `job-api-design` | ジョブ処理API設計書（SQS/Worker/DLQ）を生成 ※条件付き |
| `ops-monitoring` | 運用監視設計書（CloudWatch・Slack通知）を生成 ※条件付き |
| `running-cost` | 月額AWSコスト・年間TCOを算出 |
| `proposal` | 提案書（Ganttチャート・TCO）を生成 |
| `req-investigate` | 規約調査・ヒアリング事項レポートを生成 |
