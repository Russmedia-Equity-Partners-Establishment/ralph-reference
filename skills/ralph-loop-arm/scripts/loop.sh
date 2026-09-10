#!/bin/bash
# Ralph loop runner — unattended claude -p iterations against PRD.md + progress.txt.
# Installed into a project as .ralph/loop.sh by the ralph-loop-arm skill.
# Run from anywhere: ./.ralph/loop.sh   (works on the project it lives in)
set -uo pipefail

RALPH_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$RALPH_DIR")"
cd "$PROJECT_DIR"

# --- Config ------------------------------------------------------------------
BRANCH="loop/run"
MAX_ITERATIONS=50
REVIEW_EVERY=5
# shellcheck source=/dev/null
[ -f "$RALPH_DIR/config.env" ] && source "$RALPH_DIR/config.env"
# Telegram credentials (optional): TELEGRAM_BOT_TOKEN + TELEGRAM_CHAT_ID
# shellcheck source=/dev/null
[ -f "$HOME/.claude/ralph-loop.env" ] && source "$HOME/.claude/ralph-loop.env"

PRD="$PROJECT_DIR/PRD.md"
PROGRESS="$PROJECT_DIR/progress.txt"
LOG_DIR="$RALPH_DIR/logs"
mkdir -p "$LOG_DIR"

PROJECT_NAME="$(basename "$PROJECT_DIR")"

# --- Notification: Telegram Bot API, terminal banner as fallback --------------
notify() {
  local msg="$1"
  echo ""
  echo "================================================================"
  echo "$msg"
  echo "================================================================"
  if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
    if curl -fsS --max-time 15 \
      "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
      -d chat_id="${TELEGRAM_CHAT_ID}" \
      --data-urlencode text="$msg" >/dev/null 2>&1; then
      echo "(notified via telegram)"
    else
      echo "(telegram notification failed — terminal banner above is the record)"
    fi
  else
    echo "(no telegram config in ~/.claude/ralph-loop.env — terminal only)"
  fi
}

# --- Preflight -----------------------------------------------------------------
for f in "$PRD" "$PROGRESS" "$RALPH_DIR/iteration.md" "$RALPH_DIR/reviewer.md"; do
  if [ ! -f "$f" ]; then
    echo "ralph: missing $f — arm the project first (ralph-loop-arm skill)." >&2
    exit 1
  fi
done
if ! command -v claude >/dev/null 2>&1; then
  echo "ralph: 'claude' CLI not found in PATH." >&2
  exit 1
fi
if ! git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  echo "ralph: $PROJECT_DIR is not a git repository." >&2
  exit 1
fi
if [ -n "$(git status --porcelain)" ]; then
  echo "ralph: working tree is dirty — commit or stash before starting the loop." >&2
  exit 1
fi

# Branch isolation: reuse the loop branch if it exists, create it otherwise.
if git rev-parse --verify --quiet "$BRANCH" >/dev/null; then
  git checkout "$BRANCH" || exit 1
else
  git checkout -b "$BRANCH" || exit 1
fi

echo "ralph: project=$PROJECT_NAME branch=$BRANCH max=$MAX_ITERATIONS review_every=$REVIEW_EVERY"
echo "ralph: logs in $LOG_DIR"

# --- Loop ----------------------------------------------------------------------
iter=0
consec_fail=0
final_review_done=0
last_kind=""
outcome=""

while :; do
  # Sentinel checks (on progress.txt as committed by the last iteration)
  if grep -q '^LOOP_STUCK$' "$PROGRESS"; then
    outcome="STUCK — a task blocked twice; see progress.txt"
    break
  fi
  if grep -q '^LOOP_COMPLETE$' "$PROGRESS"; then
    if [ "$final_review_done" -eq 1 ]; then
      outcome="COMPLETE — PRD done and survived final review"
      break
    fi
    kind="reviewer"   # final adversarial pass before accepting completion
  elif [ "$iter" -ge "$MAX_ITERATIONS" ]; then
    outcome="MAX ITERATIONS ($MAX_ITERATIONS) reached — PRD not finished; see progress.txt"
    break
  elif [ "$iter" -gt 0 ] && [ $((iter % REVIEW_EVERY)) -eq 0 ] && [ "$last_kind" != "reviewer" ]; then
    kind="reviewer"
  else
    kind="iteration"
  fi

  iter=$((iter + 1))
  log="$LOG_DIR/$(printf '%03d' "$iter")-$kind.log"
  echo "ralph: [$iter/$MAX_ITERATIONS] $kind → $log"

  claude -p "$(cat "$RALPH_DIR/$kind.md")" --dangerously-skip-permissions \
    >"$log" 2>&1
  status=$?
  last_kind="$kind"

  if [ "$kind" = "reviewer" ] && grep -q '^LOOP_COMPLETE$' "$PROGRESS"; then
    # reviewer ran while sentinel present and did not remove it → completion confirmed
    final_review_done=1
  elif [ "$kind" = "reviewer" ]; then
    final_review_done=0
  fi

  if [ "$status" -ne 0 ]; then
    consec_fail=$((consec_fail + 1))
    echo "ralph: iteration $iter exited $status ($consec_fail consecutive)"
    if [ "$consec_fail" -ge 2 ]; then
      outcome="CRASHED — two consecutive iterations failed; last log: $log"
      break
    fi
  else
    consec_fail=0
  fi
done

# --- Wrap up ---------------------------------------------------------------------
done_count=$(grep -c '^\- \[x\]' "$PRD" 2>/dev/null || true)
open_count=$(grep -c '^\- \[ \]' "$PRD" 2>/dev/null || true)
notify "🔁 ralph loop [$PROJECT_NAME] finished after $iter iteration(s)
Outcome: $outcome
Tasks: ${done_count:-?} done, ${open_count:-?} open
Branch: $BRANCH — review with: git log --oneline $BRANCH"

case "$outcome" in
  COMPLETE*) exit 0 ;;
  *)         exit 2 ;;
esac
