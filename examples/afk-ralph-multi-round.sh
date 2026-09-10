#!/bin/bash
# afk-ralph.sh — autonomous Ralph loop, multi-round variant (taken from the EZPug project). ONE task per iteration.
# Advanced alternative to skills/ralph-loop-arm/scripts/loop.sh: several numbered PRDs, per-task model routing.
#
# Usage:   ./ralph/afk-ralph.sh <PRD-file> <iterations>
# Example: ./ralph/afk-ralph.sh ralph/PRD-01-foundation.md 20
#
# Each iteration reads the PRD + its progress file (<PRD>.progress.txt, created if
# missing), implements the first unchecked task, verifies, ticks the box, appends a
# progress line, commits — then loops. Stops early on <promise>COMPLETE</promise>.
#
# Model routing (see PRD-TEMPLATE.md): tasks tagged '(fable)' run on claude-fable-5,
# everything else on claude-opus-5. Override for a run with RALPH_MODEL=<model>.
# A '**Branch:** `x`' header in the PRD is enforced when present.

set -e
cd "$(dirname "$0")/.."   # repo root, regardless of caller cwd

PRD="${1:?Usage: $0 <PRD-file> <iterations>}"
ITERATIONS="${2:?Usage: $0 <PRD-file> <iterations>}"
[ -f "$PRD" ] || { echo "ERROR: PRD '$PRD' not found (paths are repo-root-relative)"; exit 1; }
PROGRESS="${PRD%.md}.progress.txt"
touch "$PROGRESS"

BRANCH=$(grep -oEm1 '\*\*Branch:\*\* `[^`]+`' "$PRD" | sed 's/.*`\(.*\)`.*/\1/' || true)
if [ -n "$BRANCH" ] && [ "$(git branch --show-current)" != "$BRANCH" ]; then
  echo "ERROR: PRD wants branch '$BRANCH', you are on '$(git branch --show-current)'."
  exit 1
fi

echo "AFK Ralph — EZPug — PRD: $PRD — up to $ITERATIONS iterations"
echo ""

for ((i=1; i<=ITERATIONS; i++)); do
  NEXT_LINE=$(grep -m1 '^- \[ \]' "$PRD" || true)
  NEXT_TASK=$(echo "$NEXT_LINE" | grep -oE 'T[0-9]+' | head -1 || true)

  if [ -n "$RALPH_MODEL" ]; then
    RUN_MODEL="$RALPH_MODEL"
  elif [[ "$NEXT_LINE" == *"(fable)"* ]]; then
    RUN_MODEL="claude-fable-5"
  else
    RUN_MODEL="claude-opus-5"
  fi

  # Trailer must name the model that actually did the work.
  case "$RUN_MODEL" in
    *fable*) TRAILER="Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>" ;;
    *haiku*) TRAILER="Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>" ;;
    *)       TRAILER="Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>" ;;
  esac

  echo "=========================================="
  echo "  Ralph $i/$ITERATIONS — $(date '+%Y-%m-%d %H:%M:%S')"
  echo "  next task: ${NEXT_TASK:-finalize} -> model: $RUN_MODEL"
  echo "=========================================="

  PROMPT="@$PRD @$PROGRESS

One EZPug Ralph iteration — ONE task per run.

1. Read CLAUDE.md, the PRD, the progress file, and the spec sections the PRD names for
   your task (specs-and-more/Project.md wins on conflict). Check 'git status': uncommitted
   changes to files this PRD owns mean a previous run died mid-task — review the partial
   work, keep what is correct, and finish that task (its box is still unchecked).
2. Pick the FIRST unchecked task ('- [ ]') in the PRD. Top-to-bottom is dependency order;
   do not skip ahead. Genuinely hard-blocked? Add a '> blocked: ...' note under it and
   take the next task only.
3. Implement that ONE task end-to-end. You own the HOW; the PRD's references win over its
   task summaries. No bundling, no stealth refactors — separate work becomes a new
   '- [ ]' line in the PRD instead.
4. Verify per the PRD's working rules and CLAUDE.md. UI tasks get a real browser check at
   1440 and 390 px with zero console warnings.
5. Tick the box, then append one line to $PROGRESS:
   '<task-id>: <what + notable decisions> — <short sha> — <date>'.
6. Commit (PRD tick + progress line included) with a scoped conventional message ending
   in: '$TRAILER'.

If every box is already checked, do the PRD's completion section if present, then output
exactly: <promise>COMPLETE</promise>"

  # A crashed run must NOT kill the loop (set -e): capture rc, warn, retry next iteration.
  set +e
  result=$(claude --dangerously-skip-permissions --model "$RUN_MODEL" -p "$PROMPT")
  rc=$?
  set -e

  echo "$result"
  echo ""

  if [ $rc -ne 0 ]; then
    echo "WARN: iteration $i exited rc=$rc (task ${NEXT_TASK:-finalize}). Box stays unchecked -> next iteration retries. Pausing 120s."
    sleep 120
    continue
  fi

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo "PRD complete after $i iterations."
    exit 0
  fi

  [ $i -lt $ITERATIONS ] && sleep 5
done

echo ""
echo "Reached $ITERATIONS iterations. Check $PROGRESS and run again to continue."
