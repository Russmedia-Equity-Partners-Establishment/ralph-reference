---
name: feedback-to-todos
description: Turn raw feedback — a chat export, an email thread, meeting notes, a voice-message transcript, a pile of loose bug reports — into implementation-ready work items, one FEAT-nn / BUG-nn markdown file each, that a Ralph loop or a human can pick up cold. Use whenever the user wants to "process feedback", "triage this", "turn this into todos / tasks / tickets", points at a feedback file, pastes a batch of complaints and wants work items out of it, or has a shipped project that needs a second round of work. Works on any stack. Feeds the ralph-loop-arm skill's work-item mode.
---

# feedback → work items

One raw feedback batch in, a set of self-contained work-item files out.

The quality bar: **a person or an agent must be able to pick up any single file cold and
implement it — without re-reading the feedback thread and without re-exploring the
codebase.** That means every item carries the verbatim feedback with its date and author, a
`file:line`-grounded explanation of how the code works today, a root cause for bugs, a
concrete plan, and verification steps using the project's real commands.

## Where this sits in the process

```
context brief ──▶ prd-grill ──▶ PRD.md ──▶ loop      (round 1: greenfield)
feedback ──▶ THIS SKILL ──▶ ToDos/*.md ──▶ PRD.md ──▶ loop   (round 2+: real usage)
```

Round 1 starts from a conversation, because nothing exists yet. Every round after that
starts from feedback about something that does exist, and a grill from scratch is the wrong
tool: it re-derives context the code already holds. Work items are the durable backlog
between rounds. The PRD is rewritten every round; the work items outlive it.

**The work item is the contract.** The PRD that follows points at these files and owns only
order, dependencies and the loop contract. Implementation detail lives here, in one place,
so nothing drifts.

## Phase 0 — Locate inputs and conventions

Establish four things before investigating anything.

1. **The feedback source.** A file, a pasted message, a chat or email export, a transcript.
   Read all of it. Do not sample.
2. **The target repo.** Usually the working directory. If the feedback clearly spans
   several repos, run this flow once per repo, with only that repo's items.
3. **The work-items folder and house style.** Look for an existing folder: `ToDos/`,
   `todos/`, `tasks/`, `backlog/`, `issues/`. If one exists, read 2 or 3 recent items and
   adopt their exact format — headings, metadata fields, section names, status vocabulary,
   language. The house style always wins over the template bundled here. If there is no
   such folder, create `ToDos/` and use [templates/work-item.md](templates/work-item.md).
4. **The next free IDs.** Work items are `{TYPE}-{NN}`: `FEAT-27`, `BUG-14`. Take the
   maximum over **both** the files on disk **and** the git history, then increment per
   prefix:

   ```sh
   git log --all --oneline | grep -oiE '(FEAT|BUG)-[0-9]+'
   ```

   Filenames alone are not enough. Many repos delete or archive an item's file once it
   ships, while the ID lives on forever in commit messages (`feat(x): … (FEAT-27)`) and in
   the changelog. A folder topping out at FEAT-25 can easily hide a shipped FEAT-27 in git,
   and reusing that number corrupts the trail from commit back to reason. Greenfield starts
   at 01.

## Phase 1 — Group the feedback

Read the whole batch and group it by **the code seam it touches**, not by who said it or
when. Three people complaining about the same slow page are one item. One person listing
five unrelated annoyances is five.

- Split a group when its halves would be implemented in different places, or could ship
  independently.
- Merge two groups when neither can be verified without the other.
- Drop nothing silently. Anything you decide is out of scope, a duplicate of an existing
  item, or already fixed goes into the Phase 4 report with the reason — the user decides
  whether to overrule you.
- Classify each group as `BUG` (something does not do what it promises) or `FEAT`
  (something does what it promises, and that is not enough).

## Phase 2 — Investigate each group in the code

Each group needs its own trip into the codebase before anything is written. Do not draft
from the feedback alone: a work item written without reading the code is a guess wearing a
ticket's clothes.

Fan the groups out in parallel — an `Explore` agent or a Workflow per group, one seam each —
and have every one of them come back with:

- **How it works today**, with `file:line`. The actual chain, not a guess at the
  architecture.
- **The root cause**, for bugs. Reproduce it in the code if you cannot run it. "The symptom
  is X" is not a root cause; "X because `session.ts:112` refreshes before the guard" is.
- **What already exists to reuse.** The helper, the pattern, the component that means this
  is a 20-line change rather than a new subsystem.
- **The real verification command** for this area, taken from the package manifest,
  Makefile, CI config or agent-guidance file. Never invented.
- **Open questions**, if a genuine decision is needed — see Phase 3 for what qualifies.

Then have a second pass **fact-check each draft against the code** before it is written to
disk. An unverified `file:line` is worse than none: it sends the implementer to the wrong
file with confidence.

## Phase 3 — Decide, don't ask

Most of what looks like an open question is not one. Settle it yourself from the code and
the feedback, and record it in the item's **Decisions taken** section. Only three kinds of
question reach the user:

1. a **scope fork** whose branches lead to materially different outcomes,
2. a **product, UX or commercial trade-off** only the stakeholder can own,
3. a **destructive or one-way-door** change: data loss, migrations, public API, anything
   costly to undo.

Ask them all at once, batched, with a recommended default first so the user can accept with
one word, and name the work item each question came from. Aim for zero to a few questions
across the whole batch. A wall of questions means the filter was not applied.

Write every answer back **into the work-item file**, as a resolved decision, and flip the
item's status from `needs-decision` to `ready`. The answer must not live only in the chat or
only in the PRD — the file is the contract, and the next round reads the file.

## Phase 4 — Write and report

1. **Write one file per group**, `ToDos/{TYPE}-{NN}-{slug}.md`, in the house style or the
   bundled template.
2. **Cross-reference** items that depend on each other with a `Related:` line, in their
   natural build order.
3. **Report in chat**: a table of `ID → type → title → status → depends-on`, what you
   dropped or merged and why, the questions you resolved yourself and how, and anything
   that needs a human outside any loop (a production migration, a credential, a decision
   still open).
4. **Offer the handoff**: `ralph-loop-arm` in work-item mode turns the ready items into a
   thin PRD and arms the loop.

## Grounding rules

- **Verbatim feedback survives.** Quote it with date and author. Paraphrase loses the one
  thing that cannot be recovered later: what the person actually said.
- **`file:line` or it did not happen.** Every claim about how the code works carries a
  pointer, and every pointer was checked.
- **Real commands only.** Verification steps come from the repo, never from memory of what
  such a project usually runs.
- **One item, one seam.** If an item cannot be verified in one sitting, it is two items.
- **Never invent scope.** An item covers what the feedback asked for plus what the code
  forces. Improvements you would like belong in the report, not in someone else's ticket.
