#!/bin/bash
# setup.sh — install the four process skills into Claude Code so /grill-me,
# /prd-grill, /feedback-to-todos and /ralph-loop-arm are available in every
# project on this machine.
#
# Usage:
#   ./setup.sh            copy skills into ~/.claude/skills (skips ones already there)
#   ./setup.sh --force    overwrite existing copies
#   ./setup.sh --link     symlink instead of copy (edits in this repo apply immediately)
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
TARGET="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
FORCE=0
LINK=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --link)  LINK=1 ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

mkdir -p "$TARGET"
installed=0
skipped=0
for skill in grill-me prd-grill feedback-to-todos ralph-loop-arm; do
  src="$HERE/skills/$skill"
  dst="$TARGET/$skill"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ "$FORCE" -eq 1 ]; then
      rm -rf "$dst"
    else
      echo "skip    $skill (already at $dst; use --force to replace)"
      skipped=$((skipped + 1))
      continue
    fi
  fi
  if [ "$LINK" -eq 1 ]; then
    ln -s "$src" "$dst"
    echo "linked  $skill -> $dst"
  else
    cp -R "$src" "$dst"
    echo "copied  $skill -> $dst"
  fi
  installed=$((installed + 1))
done
chmod +x "$TARGET/ralph-loop-arm/scripts/loop.sh" 2>/dev/null || true

echo ""
echo "$installed installed, $skipped skipped. Skills dir: $TARGET"

if command -v claude >/dev/null 2>&1; then
  echo "claude CLI found: $(command -v claude)"
else
  echo "claude CLI not found. Install it first:"
  echo "  curl -fsSL https://claude.ai/install.sh | bash"
fi

echo ""
echo "Next: a new project — run /prd-grill on your context brief."
echo "      an existing one — run /feedback-to-todos on the feedback, then /ralph-loop-arm."
