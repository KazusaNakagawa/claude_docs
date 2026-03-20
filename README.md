# claude_docs

Claude で試した内容をナレッジとして残すためのリポジトリです。

---

## ディレクトリ構成

```bash
claude_docs/
├── output/          # req-full スキルの実行結果サンプル
│   ├── case1/       # iOS版 EnglishLearnApp — スキル開発初期の出力（連番なし）
│   ├── case2/       # iOS版 EnglishLearnApp — req-full スキルによる出力（01.〜07.）
│   └── case3/       # Web版 EnglishLearnApp — React SPA 拡張時の出力（01.〜07.）
│
└── skills/          # Claude カスタムスキル集
    ├── README.md    # スキル一覧・使い方・インストール手順
    ├── install.sh   # .skill パッケージ生成スクリプト
    ├── dist/        # パッケージ済み .skill ファイル（git管理外）
    ├── req-full/    # 親スキル（以下8スキルをワンショット実行）
    ├── req-estimate/      # 設計書・工数見積もり
    ├── db-design/         # DB設計書（ER図・テーブル定義）
    ├── detail-design/     # 詳細設計書（シーケンス図・API仕様）
    ├── job-api-design/    # ジョブ処理API設計書（SQS/Worker/DLQ）※条件付き
    ├── ops-monitoring/    # 運用監視設計書（CloudWatch・Slack通知）※条件付き
    ├── running-cost/      # 月額コスト・年間TCO
    ├── proposal/          # 提案書（Ganttチャート・TCO）
    └── req-investigate/   # 規約調査・ヒアリング事項レポート
```

---

## output/ — ケース別サンプル

各ケースは同じ題材（英語学習アプリ）に対して req-full スキルを実行した出力結果です。
`app/` がアプリ本体の設計書、`aws/` が AWS インフラ拡張分の設計書を格納しています。

| ケース | 概要 | 出力ファイル |
|--------|------|------------|
| `case1/` | iOS版・スキル開発初期の出力。連番プレフィックスなし | `customer-summary.md` 他 |
| `case2/` | iOS版・現行スキルによる出力 | `01.customer-summary.md` 〜 `07.investigation-report.md` |
| `case3/` | Web版（React SPA）への拡張。既存 iOS リポジトリ + 新規設計書 | `01.customer-summary.md` 〜 `07.investigation-report.md` |

req-full が生成する設計書の一覧と各スキルの詳細は [`skills/README.md`](./skills/README.md) を参照してください。
