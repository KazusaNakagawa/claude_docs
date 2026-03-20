# Review Feedback Evaluation Criteria

## Priority Classification

レビューコメントを以下の基準で分類し、優先度順に対応する。

### P0: Blocking (必須対応)

即座に対応が必要。これが未解決だとマージ不可。

| パターン | 例 |
|---------|-----|
| セキュリティ脆弱性 | ハードコードされた秘密鍵、SQLインジェクション、XSS |
| ビルド/テスト失敗 | CI が red、コンパイルエラー |
| 明示的なブロック | `Request changes` ステータス、"must fix" コメント |
| データ損失リスク | 誤った削除ロジック、上書き処理の欠陥 |

### P1: Should Fix (強く推奨)

マージ前に対応すべき。技術的負債になりやすい。

| パターン | 例 |
|---------|-----|
| ロジックバグ | エッジケース未考慮、off-by-one エラー |
| パフォーマンス問題 | O(n²) で改善可能、不要なループ |
| API 設計の問題 | 破壊的変更、不適切な公開範囲 |
| テスト不足 | 重要パスのテストがない |

### P2: Nice to Have (推奨)

時間があれば対応。次のPRで対応してもよい。

| パターン | 例 |
|---------|-----|
| コードスタイル | フォーマット、命名規則 |
| ドキュメント改善 | コメント追加、README 更新 |
| リファクタリング提案 | より良い書き方の提案 |
| nit / minor | "nit:" で始まるコメント |

## Response Strategy

### 即対応すべきケース

- P0 は全て対応
- P1 は原則対応（工数が大きい場合はユーザーに確認）

### 確認が必要なケース

- 要件の解釈が分かれるコメント
- 大規模な設計変更の提案
- 「〜した方がいいかも」という曖昧な提案

### 対応を見送ってよいケース

- 明示的に "optional" と書かれている
- 本PRのスコープ外の改善提案（→ 別Issue化を提案）

## Comment Type Detection

コメント内のキーワードで自動分類：

| キーワード | 分類 |
|-----------|------|
| `security`, `vulnerability`, `injection`, `exposed` | P0 Security |
| `breaking`, `must`, `required`, `blocker` | P0 Blocking |
| `bug`, `incorrect`, `wrong`, `fails` | P1 Logic |
| `performance`, `slow`, `optimize` | P1 Performance |
| `nit`, `minor`, `optional`, `suggestion` | P2 Style |
| `typo`, `spelling`, `grammar` | P2 Documentation |
