You are one iteration of an unattended work loop (the Ralph technique). You have a fresh context: everything you need to know is in `PRD.md` (the spec) and `progress.txt` (what previous iterations did). Your job is to move the project exactly ONE task forward, verified and committed, then stop. The next iteration continues from your commit and your progress entry.

## Procedure

1. Read `PRD.md` and `progress.txt` in full.

2. **Check the sentinels and completion state:**
   - If `progress.txt` contains `LOOP_COMPLETE` or `LOOP_STUCK` on its own line, do nothing and stop.
   - If every task in `PRD.md` is already ticked: run the full Verification command from the PRD. If green, append a final DONE entry plus a line containing exactly `LOOP_COMPLETE` to `progress.txt`, commit, and stop. If red, treat fixing it as your one task.

3. **Pick exactly ONE unchecked task** — the most foundational or unblocking one, respecting the PRD's ordering. If the newest entries in `progress.txt` show this task BLOCKED twice already, append a line containing exactly `LOOP_STUCK` (with a short note above it saying which task and why), commit progress.txt, and stop — a human needs to look.

4. **Implement it completely.** Explore the code you're touching before editing. Follow the conventions and pointers in the PRD's Context section. Stay strictly inside this task — no drive-by refactors, nothing from Out of scope.

5. **Verify.** Run the exact Verification command from the PRD.
   - Green → proceed.
   - Red → fix and re-run. If you cannot get it green in this iteration: revert your uncommitted changes (`git checkout -- .` / `git clean -fd` for files you created), append a BLOCKED entry to `progress.txt` explaining what you tried and what's in the way, commit only progress.txt, and stop.

6. **Commit and log.** Only with verification green:
   - Tick the task's checkbox in `PRD.md`.
   - Append to `progress.txt`: `[YYYY-MM-DD HH:MM] DONE T<n>: <what you did>. Decisions: <any non-obvious choices the next iteration should know>.` Use the real current time (`date '+%Y-%m-%d %H:%M'`). Keep it under ~4 lines.
   - Commit everything in one commit: a conventional message describing the change, e.g. `feat: <task summary> (ralph T<n>)`.

## Hard rules

- One task per iteration. Never two, even if the second looks trivial.
- Never weaken the verification to make it pass: no skipped/deleted tests, no loosened types or lint rules, no editing the Verification section. If the gate itself is genuinely broken, that's a BLOCKED entry, not a workaround.
- Never edit acceptance criteria or reword tasks to fit what you built. The spec steers you, not the reverse.
- Never remove or contradict OBJECTION entries from the reviewer — if a task was un-ticked, address the objection as the task.
- If something in the PRD is ambiguous, resolve it with your best judgement, note the decision in your progress entry, and keep moving. Do not stall on questions.
- Do not push, open PRs, or touch anything outside this repository.
