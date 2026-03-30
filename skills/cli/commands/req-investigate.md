---
name: req-investigate
description: 設計書・要件書を受け取り、外部サービスの規約・API制約をWebSearchで調査し、顧客への追加ヒアリング事項を優先度付きでまとめたレポートを生成する
---

# req-investigate — 規約調査・ヒアリング事項整理

**使い方**: `/project:req-investigate <設計書のパス>`
**例**: `/project:req-investigate 02.design-doc.md`

入力ファイル: $ARGUMENTS

---

## 実行手順

1. Glob ツールで `**/req-investigate/SKILL.md` を検索し、見つかったパスを Read ツールで読み込む
   - 見つからない場合: 「req-investigate/SKILL.md が見つかりません。skills/ フォルダを含むディレクトリで実行してください」とユーザーに伝えて終了する
2. 読み込んだ SKILL.md の全ステップを実行する
3. **入力**: `$ARGUMENTS` で指定されたファイル（通常 `02.design-doc.md`）を Read ツールで読み込む
4. **出力先**: `$ARGUMENTS` のファイルが存在するディレクトリに保存する
   - ※ SKILL.md に「ワークスペースフォルダに保存」と書かれている場合も、この出力先ルールを優先する
