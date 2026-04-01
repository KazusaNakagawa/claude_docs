---
name: db-design
description: 設計書（02.design-doc.md）または要件定義書を受け取り、ER図・テーブル定義・AWS DB選定・マイグレーション方針を含むDB設計書を生成する
---

# db-design — DB設計書生成

**使い方**: `/project:db-design <設計書のパス>`
**例**: `/project:db-design 02.design-doc.md`

入力ファイル: $ARGUMENTS

---

## 実行手順

1. Glob ツールで `**/db-design/SKILL.md` を検索し、見つかったパスを Read ツールで読み込む
   - 見つからない場合: 「db-design/SKILL.md が見つかりません。skills/ フォルダを含むディレクトリで実行してください」とユーザーに伝えて終了する
2. 読み込んだ SKILL.md の全ステップを実行する
3. **入力**: `$ARGUMENTS` で指定されたファイル（`02.design-doc.md` または要件定義書）を Read ツールで読み込む
4. **出力先**: `$ARGUMENTS` のファイルが存在するディレクトリに保存する
   - ※ SKILL.md に「ワークスペースフォルダに保存」と書かれている場合も、この出力先ルールを優先する
