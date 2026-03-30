# job-api-design — ジョブ処理API設計書生成

**使い方**: `/project:job-api-design <詳細設計書のパス>`
**例**: `/project:job-api-design 04.detail-design.md`

入力ファイル: $ARGUMENTS

---

## 実行手順

1. Glob ツールで `**/job-api-design/SKILL.md` を検索し、見つかったパスを Read ツールで読み込む
   - 見つからない場合: 「job-api-design/SKILL.md が見つかりません。skills/ フォルダを含むディレクトリで実行してください」とユーザーに伝えて終了する
2. 読み込んだ SKILL.md の全ステップを実行する
3. **入力**: `$ARGUMENTS` で指定されたファイル（通常 `04.detail-design.md`）を Read ツールで読み込む
   - 同じディレクトリに `02.design-doc.md`・`03.db-design.md` があれば合わせて読み込む
4. **出力先**: `$ARGUMENTS` のファイルが存在するディレクトリに保存する
   - ※ SKILL.md に「ワークスペースフォルダに保存」と書かれている場合も、この出力先ルールを優先する
