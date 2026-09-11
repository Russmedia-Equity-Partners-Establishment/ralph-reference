---
name: ralph-loop-arm
description: Author a PRD and arm an unattended Ralph loop — overnight Claude Code iterations that pick one task, implement, verify, commit, and repeat until the spec is done. Writes the PRD either from scratch or as a thin ordering layer over a folder of work items (FEAT-nn / BUG-nn), detects round-based vs flat PRD layouts, and can route individual tasks to a stronger model. Use when the user says "ralph loop", "arm the loop", "loop this", "overnight loop", "write a PRD for the loop", "next round", "loop status", or wants unattended multi-hour agent work on a project.
---

# ralph-loop-arm

Arm a project for the Ralph technique: an unattended loop of fresh-context `claude -p` runs, steered by two files — the PRD (the spec of the end state) and the progress log (what is already done). Their names are `PRD.md` and `progress.txt` by default and `PRD-ROUND<n>.md` / `progress-r<n>.txt` in a round-based repo; `.ralph/config.env` holds whichever pair applies. Each iteration does exactly one task, verifies it, commits it, and hands over. The spec is the steering wheel: quality of spec in, quality of work out.

This skill has three phases. Route by what the user asks for. If ambiguous, ask which phase they want.

## Phase 1 — Author (write the PRD)

Input: a goal, notes, a feature list, client feedback — anything raw.

**Pick the mode first.** Look for a work-items folder (`ToDos/`, `todos/`, `tasks/`, `backlog/`, `issues/` holding `FEAT-nn` / `BUG-nn` files):

- **Work-item mode** — the folder exists and has pending items. Go to Phase 1b. This is the normal path for any round after the first.
- **Grill mode** — no work items, and the input is fuzzy or key decisions are unresolved (scope, definition of done, verification). Run the `prd-grill` skill first; it interviews the user in batches and outputs a PRD in exactly this shape. If the raw input is *feedback about something that already runs*, run `feedback-to-todos` instead to produce work items, then come back in work-item mode.
- **Direct mode** — a small, clear, greenfield change. Write the PRD yourself with the steps below.

### Direct mode

1. **Ground yourself in the project first.** Explore the repo before writing a single task. Every task must reference the actual code it touches (files, modules, patterns already in use). Never write a task you couldn't start implementing yourself right now.
2. Write the PRD at the path Phase 2 resolves (`PRD.md` by default) using `templates/PRD.md` from this skill's directory as the shape. Requirements:
   - A crisp **definition of done**.
   - Tasks as `- [ ]` checkboxes, each sized so one loop iteration (one fresh agent, one sitting) can finish it completely. Split anything bigger. Order them so foundational work comes first.
   - Per-task **acceptance criteria** — concrete and checkable, not vibes.
   - A **Verification** section with the exact shell command(s) that must pass before any commit (tests, type checks, lint, build — whatever the project has). **This is non-negotiable: if the project has no verification command, help the user create one (even a minimal smoke test) before proceeding. Never arm a loop without a verification gate.**
   - A **Findings** section: everything you traced while exploring, with `file:line`. Every fact here is a search no iteration repeats. Delete the section only if you genuinely explored nothing.
   - An **Attitude** section: the 2 to 4 standing decisions, each with its why, that an iteration checks its own choices against when the PRD does not spell something out. More than four and it stops being read.
   - An **Out of scope** section — the loop will otherwise expand into it.
3. Create the progress log from `templates/progress.txt`, filling in its header.
4. **Show the user the PRD and get explicit approval before arming.** This is their steering-wheel moment. Incorporate their edits.

Judgement guidance: don't over-constrain. The iteration agents resolve ambiguity well — give them intent and acceptance criteria, not micromanaged instructions. Ambition lives in the spec, not in a single giant task.

## Phase 1b — Author from work items

When the repo keeps work items, they are already the contract. The PRD becomes a thin ordering layer over them and nothing more.

1. **Read the pending items.** Pending means not shipped: no `Status: done`, not recorded in a past progress log, not obviously completed in `git log`. Everything pending goes into this round — there is no scope-trimming step here; the user trims by editing the folder.
2. **Resolve the open questions, once.** Collect every genuine open question across the items — a scope fork, a product trade-off, a one-way door — and ask them in a single batch with a recommended default first. Anything you can settle from the code, settle yourself. Write each answer **back into its work-item file** as a resolved decision and flip `needs-decision` to `ready`. The answer must not live only in the PRD. This is the only place a human is asked anything; after it, the loop is genuinely unattended.
3. **Order by dependency, then priority.** Schema and contracts before their consumers, plumbing before presentation, a `Related:` pair in its natural build order. Number the tasks `T1..Tn` in that final order, so "first unchecked box" is always the correct next task.
4. **Write each task thin.** One sentence of goal, a pointer to its work-item file as the contract, the surface it touches, a dependency note, a one-line verify hint. **No implementation steps** — they are in the file, and the loop owns the how. One task per work item, unless an item has clearly independent, separately shippable halves.

   ```markdown
   - [ ] **T3 — Fix stale session on refresh**: implement `ToDos/BUG-14-stale-session.md`; that file is the contract.
     - Accept: the acceptance criteria in BUG-14 all hold.
     - Depends on: T1
   ```

5. **Fill Findings and Attitude** from what the items already established, then the standing sections of the template. Do not restate what the work items or the agent-guidance file (`CLAUDE.md` / `AGENTS.md`) already say — reference them.
6. **Show the user** a table of `T-id → work item → title → depends-on`, plus the questions you resolved and how, and get approval before arming.

## Phase 2 — Arm (install the runner)

Only after the PRD is approved:

### Resolve the file names first

Before writing anything, detect which layout this repo uses and mirror it. Guessing here is how a round silently overwrites the previous one.

- **Round-based** — `PRD-ROUND<n>.md` with `progress-r<n>.txt`, often several side by side. The next round is `PRD-ROUND<n+1>.md` with a fresh `progress-r<n+1>.txt`. **Leave every earlier round untouched.** They are the history of the project and the reason a later reader can tell what was decided when.
- **Flat** — `PRD.md` with `progress.txt`. Keep the same names. If a `PRD.md` is already there from a finished round, archive it to `PRD-archive-<YYYY-MM-DD>.md` and archive the progress log beside it as `progress-archive-<YYYY-MM-DD>.txt` before writing the new pair. Never append a new round to a used progress log: the runner's sentinel checks read the whole file, and a stale `LOOP_COMPLETE` stops the new loop on iteration one.
- **Greenfield** — nothing there. Use the flat names.

When in doubt, mirror what is already on disk. Two rounds live in the same repo more often than one, and the flat layout stops paying off around the third round — say so and offer the switch.

### Install the runner

1. Create `.ralph/` at the project root and copy into it from this skill's directory:
   - `scripts/loop.sh` (make it executable)
   - `prompts/iteration.md`
   - `prompts/reviewer.md`
2. Write `.ralph/config.env`:
   ```
   BRANCH=loop/<short-slug-for-this-prd>
   PRD_FILE=PRD.md               # or PRD-ROUND7.md
   PROGRESS_FILE=progress.txt    # or progress-r7.txt
   MAX_ITERATIONS=50
   REVIEW_EVERY=5
   # Optional per-task model routing. Off while ALT_MODEL is empty.
   # ALT_MODEL=claude-fable-5
   # ALT_TAG="(fable)"   # quote it: unquoted parentheses are a bash array
   ```
   Adjust MAX_ITERATIONS to roughly 2× the task count (floor 20, default 50). `PRD_FILE` and `PROGRESS_FILE` are relative to the project root and must match the names resolved above — the runner substitutes them into both prompts, so the iteration agent reads the right pair.

   **Model routing stays off unless the user asks for it.** When it is on, tasks tagged with `ALT_TAG` run on `ALT_MODEL` and everything else on the default model. Reserve the tag for work that must be right first time: architecture and package boundaries, contract design, core state machines, load-bearing algorithms, gnarly cross-cutting debugging. Mechanical follow-ups and page work stay on the default. Tagging half the PRD defeats the point and burns the usage limit before morning.
3. Ensure `.ralph/logs/` is in `.gitignore` (append if missing).
4. Commit the PRD, the progress log, and `.ralph/` on the current branch ("arm ralph loop: <slug>").
5. Tell the user to launch it in a real terminal (not from this session — it must survive the session ending):
   ```bash
   nohup ./.ralph/loop.sh > .ralph/logs/runner.log 2>&1 &
   ```
   or in tmux/a spare terminal tab, plainly: `./.ralph/loop.sh`
6. Mention notification setup once: Telegram fires if `~/.claude/ralph-loop.env` exists with `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` (a Bot API bot, not the MCP). Without it, the outcome banner just prints in the terminal — that is the fallback.

## Phase 3 — Status (check on a loop)

When asked how a loop is doing:

1. Read `.ralph/config.env` for `PRD_FILE`, `PROGRESS_FILE` and `BRANCH` — do not assume `PRD.md`.
2. Read the progress log — the narrative of what's done, decisions, blockers, objections. Then the PRD — count ticked vs. unticked boxes.
3. `git log --oneline` on the loop branch — one commit per iteration is healthy.
4. Skim the newest files in `.ralph/logs/` for the last iteration's story, and `.ralph/logs/runner.log` if launched with nohup.
5. Report: tasks done/remaining, sentinels present (`LOOP_COMPLETE` / `LOOP_STUCK`), blockers or reviewer objections, which model ran which iteration if routing is on, and whether the runner is still alive (`pgrep -f ralph/loop.sh` — note the path pattern matches `.ralph/loop.sh`).

## How the loop behaves (for reference)

- Runs on branch `loop/<slug>`; you review and merge in the morning.
- Every iteration is a fresh `claude -p` with `--dangerously-skip-permissions` reading only the PRD + progress pair named in `config.env`. One task, verify, commit, log.
- With routing on, the runner reads the next unchecked task before each iteration and picks the model from its tag, then tells the agent which commit trailer to use so the log shows which model did the work.
- Every `REVIEW_EVERY`-th iteration, and once when the loop believes it is finished, an **adversarial reviewer** runs instead: it attacks recently ticked tasks against their acceptance criteria and un-ticks anything that doesn't survive, with a written objection. Nothing is done until it has survived the skeptic.
- Stops on: `LOOP_COMPLETE` in the progress log (after surviving final review), `LOOP_STUCK` (same task blocked twice), two consecutive crashed iterations, or MAX_ITERATIONS.
- A bad iteration costs one commit, never the project.
