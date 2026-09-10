# PRD: <project / feature name>

<!-- This file steers an unattended Ralph loop. Each iteration is a fresh agent
     that reads this file and progress.txt, picks ONE unchecked task, implements
     it, runs the Verification command, commits, and ticks the box.
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

## Tasks

<!-- One iteration per task. Order foundational-first. Each task: what + where
     + acceptance criteria. Split anything an agent can't finish in one sitting. -->

- [ ] **T1 — <short name>**: <what to build/change, referencing real files or modules>
  - Accept: <concrete, checkable criteria>
- [ ] **T2 — <short name>**: <...>
  - Accept: <...>

## Out of scope

<Explicitly list what the loop must NOT touch or attempt, or it will expand into it.>

## Notes

<Anything else: gotchas, credentials handling, style decisions already made.>
