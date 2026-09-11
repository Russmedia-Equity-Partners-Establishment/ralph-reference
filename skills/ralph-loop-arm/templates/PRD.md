# PRD: <project / feature name>

<!-- This file steers an unattended Ralph loop. Each iteration is a fresh agent
     that reads this file and the progress file, picks ONE unchecked task,
     implements it, runs the Verification command, commits, and ticks the box.
     Write for a competent engineer with zero context beyond this repo. -->

## Goal

<One paragraph: what exists when this is done, and why it matters.>

## Definition of done

<The end state, stated so completion is checkable, not arguable.
E.g. "All tasks below ticked, `npm test && tsc --noEmit` green, app builds and
the three user flows X/Y/Z work end to end.">

## Verification

Every iteration MUST run this and see it pass before committing:

```bash
<exact command(s), e.g. npm test && npx tsc --noEmit>
```

## Context

<What the loop agent needs to know about this codebase: stack, key directories,
conventions to follow, where similar patterns already live. Point at real files.>

## Findings

<!-- Only if investigation happened before this PRD was written. Write down what
     you traced, with file:line, and what already exists to reuse. Every fact
     recorded here is a search no iteration has to repeat — this is the single
     cheapest section in the file. Delete the section when it is empty; never
     leave a placeholder. -->

- <`src/auth/session.ts:112` — sessions are refreshed here, not in the middleware.>
- <`packages/ui/Table.tsx` already does the paging pattern this round needs.>

## Attitude

<!-- The 2 to 4 standing decisions that keep every task honest, each with its why.
     These are the lines an iteration checks its own choices against when the PRD
     does not spell something out. Keep it short: this is not a style guide, it is
     the handful of calls that would otherwise drift from task to task. -->

- <Prefer extending the existing X over introducing Y — we pay for every new dependency in review time.>
- <No schema change in this round — the migration is a separate, human-run step.>

## Tasks

<!-- One iteration per task. Order foundational-first. Each task: what + where
     + acceptance criteria. Split anything an agent can't finish in one sitting.

     If this repo keeps work items (ToDos/FEAT-nn, BUG-nn), the work-item file is
     the contract: point the task at it and do NOT restate its implementation
     detail here. The PRD owns order, dependencies and the loop contract; the
     work item owns the how.

     Model routing (optional, off unless ALT_MODEL is set in .ralph/config.env):
     tag a task with the routing tag — e.g. `(fable)` — to run just that task on
     the stronger model. Reserve it for work that must be right first time:
     architecture, contracts, core state machines, load-bearing algorithms. -->

- [ ] **T1 — <short name>**: <what to build/change, referencing real files or modules>
  - Accept: <concrete, checkable criteria>
- [ ] **T2 — <short name>**: <what to build/change; or: implement `ToDos/FEAT-07.md` — that file is the contract>
  - Accept: <concrete, checkable criteria>
  - Depends on: T1

## Out of scope

<Explicitly list what the loop must NOT touch or attempt, or it will expand into it.>

## Notes

<Anything else: gotchas, credentials handling, style decisions already made.>
