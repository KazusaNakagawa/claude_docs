#!/usr/bin/env bash
# ============================================================
# install.sh — Claude スキルをパッケージして .skill ファイルを生成する
#
# 使い方:
#   bash install.sh                  # 全スキルをパッケージ
#   bash install.sh req-estimate     # 指定スキルのみ
#
# 出力先: skills/dist/<skill-name>.skill
# ============================================================

set -e

SKILLS_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="$SKILLS_DIR/dist"
TARGET="$1"

# .skill ファイルは zip アーカイブ
package_skill() {
  local skill_name="$1"
  local skill_dir="$SKILLS_DIR/$skill_name"

  if [ ! -f "$skill_dir/SKILL.md" ]; then
    echo "❌  $skill_name: SKILL.md が見つかりません (スキップ)"
    return 1
  fi

  mkdir -p "$DIST_DIR"
  local output="$DIST_DIR/${skill_name}.skill"

  # /tmp で作成してからコピー（macOS の権限制限を回避）
  local tmp_output="/tmp/${skill_name}.skill"
  rm -f "$tmp_output"

  # zip で固める (evals/ は除外 — 本番スキルには不要)
  cd "$SKILLS_DIR"
  zip -r "$tmp_output" "$skill_name/" \
    --exclude "*/evals/*" \
    --exclude "*/__pycache__/*" \
    --exclude "*/.DS_Store" \
    -q

  cp "$tmp_output" "$output"
  rm -f "$tmp_output"

  echo "✅  $skill_name → dist/${skill_name}.skill"
}

echo "============================================"
echo " Claude Skill Packager"
echo "============================================"

if [ -n "$TARGET" ]; then
  # 指定スキルのみ
  package_skill "$TARGET"
else
  # skills/ 直下のディレクトリをすべてパッケージ
  for dir in "$SKILLS_DIR"/*/; do
    skill_name="$(basename "$dir")"
    # README や dist フォルダはスキップ
    if [ "$skill_name" = "dist" ] || [ ! -f "$dir/SKILL.md" ]; then
      continue
    fi
    package_skill "$skill_name"
  done
fi

echo ""
echo "出力先: $DIST_DIR"
echo ""
echo "次のステップ:"
echo "  1. dist/*.skill ファイルを Claude デスクトップアプリに"
echo "     ドラッグ&ドロップしてインストール"
echo "  2. 既にインストール済みの場合は一度アンインストール後に再インストール"
