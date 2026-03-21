# VOICEVOX TTS インフラ (AWS CDK)

ずんだもん音声サービスを AWS Lambda + API Gateway で動かすための CDK インフラコードです。
要件詳細: [`docs/00.zundamon_voice_cloud_requirements.md`](../docs/00.zundamon_voice_cloud_requirements.md)

---

## アーキテクチャ

```bash
iOS App
  └── API Gateway (HTTP API)
        └── Lambda (Container Image)
              ├── Lambda Web Adapter  ← HTTP サーバーと Lambda を橋渡し
              └── VOICEVOX engine     ← TTS 本体 (port 50021)
```

### 採用理由

| 比較項目 | Lambda (採用) | ECS Fargate |
| ---------- | -------------- | ------------- |
| アイドルコスト | $0 | scale-to-zero の設定が複雑 |
| PoC 月額概算 | ほぼ $0 (Free Tier 内) | $1〜10/月 |
| コールドスタート | 10〜30 秒 (許容) | 1〜2 分 |
| セットアップ | 低 | 高 (ALB + Auto Scaling 必要) |

---

## ディレクトリ構成

```bash
aws/
├── bin/
│   └── app.ts                  # CDK アプリエントリーポイント
├── lib/
│   └── voicevox-stack.ts       # Lambda / API Gateway の定義
├── lambda/
│   └── voicevox/
│       └── Dockerfile          # VOICEVOX engine + Lambda Web Adapter
├── cdk.json
├── package.json
├── tsconfig.json
└── README.md
```

---

## ステージ

### PoC (現在)

- **目的**: 動作確認・コスト検証
- **スタック名**: `VoicevoxStack`
- **リージョン**: `ap-northeast-1` (東京)
- **CORS**: `allowOrigins: ['*']` (全オープン)
- **認証**: なし
- **コールドスタート**: 許容

### 本番 (将来)

- CORS を特定オリジンに制限
- API Gateway に認証追加 (Cognito または API Key)
- コールドスタート対策: Provisioned Concurrency または ECS Fargate へ移行
- 同一テキストの S3 音声キャッシュで重複生成を削減

---

## 前提条件

- Node.js 20+
- Docker (CDK デプロイ時にイメージビルドに使用)
- AWS CLI 設定済み (`aws configure`)
- CDK Bootstrap 実行済み (初回のみ)

---

## セットアップ

```bash
cd aws
npm install
```

---

## デプロイ

### 初回のみ: Bootstrap

```bash
npx cdk bootstrap
```

### 差分確認

```bash
npm run diff
```

### デプロイ

```bash
npm run deploy
```

デプロイ完了後、Outputs に API エンドポイントが出力されます。

```bash
Outputs:
VoicevoxStack.VoicevoxApiEndpoint = https://xxxxxxxxxx.execute-api.ap-northeast-1.amazonaws.com
VoicevoxStack.VoicevoxFunctionArn = arn:aws:lambda:ap-northeast-1:...
```

### 削除

```bash
npm run destroy
```

---

## API エンドポイント

ベース URL: `https://<api-id>.execute-api.ap-northeast-1.amazonaws.com`

| メソッド | パス | 説明 |
| ------ | ------ | ------ |
| `GET` | `/version` | バージョン確認 / ヘルスチェック |
| `GET` | `/speakers` | 利用可能な話者一覧 |
| `POST` | `/audio_query` | テキスト → 音声合成クエリ生成 |
| `POST` | `/synthesis` | クエリ → WAV バイナリ生成 |

### 音声合成フロー (2ステップ)

**Step 1: クエリ生成**

```bash
curl -G -X POST "${BASE_URL}/audio_query" \
  --data-urlencode "text=ずんだもんです" \
  -d "speaker=3" \
  -o query.json
```

**Step 2: 音声合成**

```bash
curl -X POST \
  "${BASE_URL}/synthesis?speaker=3" \
  -H "Content-Type: application/json" \
  -d @query.json \
  -o output.wav
```

> **speaker=3** はずんだもん (ノーマル) の ID です。`GET /speakers` で全話者一覧を確認できます。

---

## Lambda 構成

| 項目 | 値 |
| ------ | ----- |
| ランタイム | Container Image |
| メモリ | 2048 MB |
| タイムアウト | 120 秒 |
| アーキテクチャ | x86_64 |
| ベースイメージ | `voicevox/voicevox_engine:cpu-ubuntu22.04-0.25.1` |

### Lambda Web Adapter について

VOICEVOX engine は HTTP サーバーとして動作するため、Lambda のイベントハンドラーとして直接動かせません。
[AWS Lambda Web Adapter](https://github.com/awslabs/aws-lambda-web-adapter) を Lambda Extension として配置することで、API Gateway のリクエストを VOICEVOX engine の HTTP エンドポイントに透過的に転送します。

```bash
API Gateway → Lambda Web Adapter (extension) → VOICEVOX engine (:50021)
```

| 環境変数 | 値 | 説明 |
| --------- | ----- | ------ |
| `PORT` | `50021` | VOICEVOX が listen するポート |
| `ASYNC_INIT` | `true` | 起動完了前に Lambda を初期化済みとしてマーク |
| `READINESS_CHECK_PATH` | `/version` | 起動完了の確認パス |

---

## 注意事項

- **コールドスタート**: 初回リクエスト時に 10〜30 秒の遅延が発生します。PoC では許容範囲とします。
- **イメージサイズ**: VOICEVOX engine イメージは数 GB あるため、初回の ECR プッシュに時間がかかります。
