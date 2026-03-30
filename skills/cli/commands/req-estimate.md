# req-estimate — 要件見積もり・実現可否判断

**使い方**: `/project:req-estimate <要件定義書のパス>`
**例**: `/project:req-estimate README.md`

入力ファイル: $ARGUMENTS

---

## 実行手順

1. Glob ツールで `**/req-estimate/SKILL.md` を検索し、見つかったパスを Read ツールで読み込む
   - 見つからない場合: 「req-estimate/SKILL.md が見つかりません。skills/ フォルダを含むディレクトリで実行してください」とユーザーに伝えて終了する
2. 読み込んだ SKILL.md の全ステップを実行する
3. **入力**: `$ARGUMENTS` で指定されたファイルを Read ツールで読み込む
4. **出力先**: `$ARGUMENTS` のファイルが存在するディレクトリに保存する
   - 例: `$ARGUMENTS` が `path/to/README.md` なら `path/to/` に出力する
   - 例: `$ARGUMENTS` が `README.md` ならカレントディレクトリに出力する
   - ※ SKILL.md に「ワークスペースフォルダに保存」と書かれている場合も、この出力先ルールを優先する
