#!/usr/bin/env bash
# ============================================================
# install.sh — CLI スラッシュコマンドを .claude/commands/ に展開する
#
# 使い方:
#   bash skills/cli/install.sh                    # カレントディレクトリの .claude/commands/ に展開
#   bash skills/cli/install.sh /path/to/project   # 指定プロジェクトの .claude/commands/ に展開
#   bash skills/cli/install.sh . req-full         # 指定コマンドのみ展開
#
# 前提:
#   - このスクリプトは claude_docs/skills/ から相対的に呼び出せる
#   - .claude/commands/ は Claude Code が自動認識するスラッシュコマンドの置き場所
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMMANDS_SRC="$SCRIPT_DIR/commands"

# 引数処理
TARGET_PROJECT="${1:-.}"   # 第1引数: インストール先プロジェクトのルート（省略時はカレント）
TARGET_CMD="${2:-}"        # 第2引数: 特定コマンドのみインストール（省略時は全部）

TARGET_DIR="$TARGET_PROJECT/.claude/commands"

echo "============================================"
echo " Claude Code CLI Skill Installer"
echo "============================================"
echo " インストール先: $TARGET_DIR"
echo ""

# .claude/commands/ を作成
mkdir -p "$TARGET_DIR"

install_command() {
  local cmd_file="$1"
  local cmd_name
  cmd_name="$(basename "$cmd_file")"
  cp "$cmd_file" "$TARGET_DIR/$cmd_name"
  echo "✅  $cmd_name → $TARGET_DIR/$cmd_name"
}

if [ -n "$TARGET_CMD" ]; then
  # 指定コマンドのみ
  if [ -f "$COMMANDS_SRC/${TARGET_CMD}.md" ]; then
    install_command "$COMMANDS_SRC/${TARGET_CMD}.md"
  else
    echo "❌  コマンドが見つかりません: $TARGET_CMD"
    exit 1
  fi
else
  # 全コマンドをインストール
  for cmd_file in "$COMMANDS_SRC"/*.md; do
    install_command "$cmd_file"
  done
fi

echo ""
echo "============================================"
echo " インストール完了！"
echo "============================================"
echo ""
echo "Claude Code で以下のスラッシュコマンドが使えるようになります:"
echo ""
echo "  /project:req-full <要件定義書>        # 設計書一式をワンショット生成"
echo "  /project:req-estimate <要件定義書>    # 見積もり・設計書"
echo "  /project:db-design <設計書>           # DB設計書"
echo "  /project:detail-design <設計書>       # 詳細設計書"
echo "  /project:job-api-design <詳細設計書>  # ジョブ処理API設計書"
echo "  /project:ops-monitoring <設計書>      # 運用監視設計書"
echo "  /project:running-cost <設計書>        # 運用コスト試算"
echo "  /project:proposal <顧客サマリー>      # 提案書"
echo "  /project:req-investigate <設計書>     # 規約調査レポート"
echo ""
echo "注意: スキルの実体（SKILL.md）は skills/<name>/SKILL.md に存在している必要があります。"
echo "      Claude Code を実行するディレクトリから Glob で検索されます。"
echo ""
echo "次のステップ:"
echo "  1. claude_docs リポジトリのルートで Claude Code を起動する"
echo "  2. /project:req-full README.md と入力して動作確認する"
