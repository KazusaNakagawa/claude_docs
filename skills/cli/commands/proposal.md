---
name: proposal
description: 顧客サマリーと運用コスト試算を受け取り、費用・Ganttチャート・3年間TCOを含む経営者・意思決定者向け提案書を生成する
---

# proposal — 提案書生成

**使い方**: `/project:proposal <顧客サマリーのパス>`
**例**: `/project:proposal 01.customer-summary.md`

入力ファイル: $ARGUMENTS

---

## 実行手順

1. Glob ツールで `**/proposal/SKILL.md` を検索し、見つかったパスを Read ツールで読み込む
   - 見つからない場合: 「proposal/SKILL.md が見つかりません。skills/ フォルダを含むディレクトリで実行してください」とユーザーに伝えて終了する
2. 読み込んだ SKILL.md の全ステップを実行する
3. **入力**: `$ARGUMENTS` で指定されたファイル（通常 `01.customer-summary.md`）を Read ツールで読み込む
   - 同じディレクトリに `05.running-cost.md`・`02.design-doc.md` があれば合わせて読み込む
4. **出力先**: `$ARGUMENTS` のファイルが存在するディレクトリに保存する
   - ※ SKILL.md に「ワークスペースフォルダに保存」と書かれている場合も、この出力先ルールを優先する
