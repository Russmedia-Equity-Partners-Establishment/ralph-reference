# {TYPE}-{NN}: <short imperative title>

**Type:** BUG | FEAT
**Status:** ready | needs-decision | blocked
**Created:** <YYYY-MM-DD>
**Surface:** <the directories this touches>
**Related:** <IDs of items this depends on or belongs with, in build order — delete if none>

## The feedback

<!-- Verbatim. Date and author. Several quotes if several people said it. This is the
     one thing that cannot be reconstructed later — never paraphrase it away. -->

> <quote> — <author>, <YYYY-MM-DD>

## How it works today

<!-- The actual chain, with file:line, checked against the code. Not an architecture
     summary: the specific path the feedback is about. -->

- `<path:line>` — <what happens here>
- `<path:line>` — <and then here>

## Root cause

<!-- BUG only. Why it misbehaves, at a named place in the code. Delete for FEAT. -->

<`path:line` does X, which means Y whenever Z.>

## What to do

<!-- The plan, not the patch. Enough that an implementer starts immediately and still
     owns the engineering choices. Name what already exists to reuse. -->

- <step, pointing at real files>
- <reuse `<path>` rather than writing a new one>

## Acceptance criteria

- [ ] <concrete and checkable — behaviour, not effort>
- [ ] <the feedback's author would agree this is fixed>

## Verification

```bash
<the repo's real command(s) for this area>
```

<Plus any manual check: the route to open, the input to try, what should appear.>

## Out of scope

- <the adjacent thing this deliberately does not touch>

## Decisions taken

<!-- Every question that came up and how it was settled, whether you settled it or the
     stakeholder did. Dated, one line each. This is what stops the same question being
     asked again next round. -->

- <YYYY-MM-DD> <the decision, and by whom>

## Open questions

<!-- Only genuine human calls: a scope fork, a product trade-off, a one-way door.
     Delete the section when empty — an empty Open questions section reads as unfinished
     work and keeps the item out of the loop. -->

- <the question, with your recommended default>
