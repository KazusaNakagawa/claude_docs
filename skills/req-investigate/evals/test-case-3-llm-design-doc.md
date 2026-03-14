# 設計書 — 社内ドキュメント検索 AI

## 概要
社内の Confluence・Google Drive のドキュメントを Claude API で検索・要約するシステム。

## 技術的実現可否
**判断: 条件付き対応可能**
- Claude API は利用可能
- Confluence / Google Drive の API 連携は要調査
- 社内データを外部LLMに送信することのセキュリティポリシーが未確認

## 不明点・確認事項
1. Anthropic の商用利用規約・データ学習ポリシー
2. Confluence API のレート制限・認証方式
3. Google Drive API の利用条件
4. 社内セキュリティポリシー上、外部APIへのデータ送信が許可されているか
5. Claude API の入力データが学習に使われるか
