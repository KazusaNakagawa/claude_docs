#!/usr/bin/env bash
# ============================================================
# install.sh — CLI スラッシュコマンドを .claude/commands/ に展開する
#
# 使い方:
#   bash skills/cli/install.sh                       # プロジェクトローカル（カレントディレクトリ）
#   bash skills/cli/install.sh --global              # ユーザーグローバル（~/.claude/commands/）
#   bash skills/cli/install.sh /path/to/project      # 指定プロジェクトのローカル
#   bash skills/cli/install.sh . req-full            # 特定コマンドのみ（プロジェクトローカル）
#   bash skills/cli/install.sh --global req-full     # 特定コマンドのみ（グローバル）
#
# インストール先の違い:
#   プロジェクトローカル → .claude/commands/ （そのプロジェクトで claude を起動したときのみ有効）
#                           コマンドは /project:<name> で呼び出す
#   ユーザーグローバル   → ~/.claude/commands/ （どのプロジェクトでも常に有効）
#                           コマンドは /<name> で呼び出す
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMMANDS_SRC="$SCRIPT_DIR/commands"

# 引数処理
if [ "$1" = "--global" ]; then
  TARGET_DIR="$HOME/.claude/commands"
  TARGET_CMD="${2:-}"
  MODE="global"
else
  TARGET_PROJECT="${1:-.}"
  TARGET_CMD="${2:-}"
  TARGET_DIR="$TARGET_PROJECT/.claude/commands"
  MODE="local"
fi

echo "============================================"
echo " Claude Code CLI Skill Installer"
echo "============================================"
if [ "$MODE" = "global" ]; then
  echo " モード    : ユーザーグローバル（全プロジェクト共通）"
  echo " 呼び出し  : /<name>  例) /req-full README.md"
else
  echo " モード    : プロジェクトローカル"
  echo " 呼び出し  : /project:<name>  例) /project:req-full README.md"
fi
echo " インストール先: $TARGET_DIR"
echo ""

mkdir -p "$TARGET_DIR"

install_command() {
  local cmd_file="$1"
  local cmd_name
  cmd_name="$(basename "$cmd_file")"
  cp "$cmd_file" "$TARGET_DIR/$cmd_name"
  echo "✅  $cmd_name → $TARGET_DIR/$cmd_name"
}

if [ -n "$TARGET_CMD" ]; then
  if [ -f "$COMMANDS_SRC/${TARGET_CMD}.md" ]; then
    install_command "$COMMANDS_SRC/${TARGET_CMD}.md"
  else
    echo "❌  コマンドが見つかりません: $TARGET_CMD"
    exit 1
  fi
else
  for cmd_file in "$COMMANDS_SRC"/*.md; do
    install_command "$cmd_file"
  done
fi

echo ""
echo "============================================"
echo " インストール完了！"
echo "============================================"
echo ""

if [ "$MODE" = "global" ]; then
  echo "どのプロジェクトでも以下のコマンドが使えます（claude 再起動で反映）:"
  echo ""
  echo "  /req-full <要件定義書>        # 設計書一式をワンショット生成"
  echo "  /req-estimate <要件定義書>    # 見積もり・設計書"
  echo "  /db-design <設計書>           # DB設計書"
  echo "  /detail-design <設計書>       # 詳細設計書"
  echo "  /job-api-design <詳細設計書>  # ジョブ処理API設計書"
  echo "  /ops-monitoring <設計書>      # 運用監視設計書"
  echo "  /running-cost <設計書>        # 運用コスト試算"
  echo "  /proposal <顧客サマリー>      # 提案書"
  echo "  /req-investigate <設計書>     # 規約調査レポート"
else
  echo "このプロジェクト（claude_docsディレクトリで起動した claude）で使えます:"
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
fi
echo ""
echo "注意: スキルの実体（SKILL.md）は skills/<name>/SKILL.md に存在している必要があります。"
echo "      Claude Code を実行するディレクトリから Glob で検索されます。"
