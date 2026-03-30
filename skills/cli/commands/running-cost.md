# running-cost — 運用コスト試算

**使い方**: `/project:running-cost <設計書のパス>`
**例**: `/project:running-cost 02.design-doc.md`

入力ファイル: $ARGUMENTS

---

## 実行手順

1. Glob ツールで `**/running-cost/SKILL.md` を検索し、見つかったパスを Read ツールで読み込む
   - 見つからない場合: 「running-cost/SKILL.md が見つかりません。skills/ フォルダを含むディレクトリで実行してください」とユーザーに伝えて終了する
2. 読み込んだ SKILL.md の全ステップを実行する
3. **入力**: `$ARGUMENTS` で指定されたファイル（通常 `02.design-doc.md`）を Read ツールで読み込む
4. **出力先**: `$ARGUMENTS` のファイルが存在するディレクトリに保存する
   - ※ SKILL.md に「ワークスペースフォルダに保存」と書かれている場合も、この出力先ルールを優先する
