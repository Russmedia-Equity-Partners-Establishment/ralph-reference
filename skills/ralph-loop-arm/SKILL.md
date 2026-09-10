---
name: ralph-loop-arm
description: Author a PRD and arm an unattended Ralph loop — overnight Claude Code iterations that pick one task, implement, verify, commit, and repeat until the spec is done. Use when the user says "ralph loop", "arm the loop", "loop this", "overnight loop", "write a PRD for the loop", "loop status", or wants unattended multi-hour agent work on a project.
---

# ralph-loop-arm

Arm a project for the Ralph technique: an unattended loop of fresh-context `claude -p` runs, steered by two files — `PRD.md` (the spec of the end state) and `progress.txt` (what is already done). Each iteration does exactly one task, verifies it, commits it, and hands over. The spec is the steering wheel: quality of spec in, quality of work out.

This skill has three phases. Route by what the user asks for. If ambiguous, ask which phase they want.

## Phase 1 — Author (write the PRD)

Input: a goal, notes, a feature list, client feedback — anything raw.

If the input is fuzzy or key decisions are unresolved (scope, definition of done, verification), consider running the `prd-grill` skill first — it interviews the user one question at a time until the spec is complete, and outputs a PRD in exactly this shape.

1. **Ground yourself in the project first.** Explore the repo before writing a single task. Every task must reference the actual code it touches (files, modules, patterns already in use). Never write a task you couldn't start implementing yourself right now.
2. Write `PRD.md` at the project root using `templates/PRD.md` from this skill's directory as the shape. Requirements:
   - A crisp **definition of done**.
   - Tasks as `- [ ]` checkboxes, each sized so one loop iteration (one fresh agent, one sitting) can finish it completely. Split anything bigger. Order them so foundational work comes first.
   - Per-task **acceptance criteria** — concrete and checkable, not vibes.
   - A **Verification** section with the exact shell command(s) that must pass before any commit (tests, type checks, lint, build — whatever the project has). **This is non-negotiable: if the project has no verification command, help the user create one (even a minimal smoke test) before proceeding. Never arm a loop without a verification gate.**
   - An **Out of scope** section — the loop will otherwise expand into it.
3. Create `progress.txt` at the project root from `templates/progress.txt`.
4. **Show the user the PRD and get explicit approval before arming.** This is their steering-wheel moment. Incorporate their edits.

Judgement guidance: don't over-constrain. The iteration agents resolve ambiguity well — give them intent and acceptance criteria, not micromanaged instructions. Ambition lives in the spec, not in a single giant task.

## Phase 2 — Arm (install the runner)

Only after the PRD is approved:

1. Create `.ralph/` at the project root and copy into it from this skill's directory:
   - `scripts/loop.sh` (make it executable)
   - `prompts/iteration.md`
   - `prompts/reviewer.md`
2. Write `.ralph/config.env`:
   ```
   BRANCH=loop/<short-slug-for-this-prd>
   MAX_ITERATIONS=50
   REVIEW_EVERY=5
   ```
   Adjust MAX_ITERATIONS to roughly 2× the task count (floor 20, default 50).
3. Ensure `.ralph/logs/` is in `.gitignore` (append if missing).
4. Commit `PRD.md`, `progress.txt`, and `.ralph/` on the current branch ("arm ralph loop: <slug>").
5. Tell the user to launch it in a real terminal (not from this session — it must survive the session ending):
   ```bash
   nohup ./.ralph/loop.sh > .ralph/logs/runner.log 2>&1 &
   ```
   or in tmux/a spare terminal tab, plainly: `./.ralph/loop.sh`
6. Mention notification setup once: Telegram fires if `~/.claude/ralph-loop.env` exists with `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` (a Bot API bot, not the MCP). Without it, the outcome banner just prints in the terminal — that is the fallback.

## Phase 3 — Status (check on a loop)

When asked how a loop is doing:

1. Read `progress.txt` — the narrative of what's done, decisions, blockers, objections.
2. Read `PRD.md` — count ticked vs. unticked boxes.
3. `git log --oneline` on the loop branch — one commit per iteration is healthy.
4. Skim the newest files in `.ralph/logs/` for the last iteration's story, and `.ralph/logs/runner.log` if launched with nohup.
5. Report: tasks done/remaining, sentinels present (`LOOP_COMPLETE` / `LOOP_STUCK`), blockers or reviewer objections, and whether the runner is still alive (`pgrep -f ralph/loop.sh` — note the path pattern matches `.ralph/loop.sh`).

## How the loop behaves (for reference)

- Runs on branch `loop/<slug>`; you review and merge in the morning.
- Every iteration is a fresh `claude -p` with `--dangerously-skip-permissions` reading only PRD + progress. One task, verify, commit, log.
- Every `REVIEW_EVERY`-th iteration, and once when the loop believes it is finished, an **adversarial reviewer** runs instead: it attacks recently ticked tasks against their acceptance criteria and un-ticks anything that doesn't survive, with a written objection. Nothing is done until it has survived the skeptic.
- Stops on: `LOOP_COMPLETE` in progress.txt (after surviving final review), `LOOP_STUCK` (same task blocked twice), two consecutive crashed iterations, or MAX_ITERATIONS.
- A bad iteration costs one commit, never the project.
