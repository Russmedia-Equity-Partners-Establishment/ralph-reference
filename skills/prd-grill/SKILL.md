---
name: prd-grill
description: Relentlessly interview the user in large batches of questions — as many per round as possible to minimize round-trips — until there is enough shared understanding to write a complete PRD. Use when the user says "grill me", "prd grill", "interview me about", "spec this out with me", "help me write a PRD", or has a fuzzy goal that needs to become a loop-ready spec.
---

# prd-grill

Turn a fuzzy goal into a complete, implementation-ready PRD by interviewing the user until every branch of the decision tree is resolved. The output is a `PRD.md` in the shape used by the `ralph-loop-arm` skill (`~/.claude/skills/ralph-loop-arm/templates/PRD.md`), so a finished grill can be armed as an overnight loop immediately — but the skill also works standalone for any spec.

The bar for "done grilling": **a fresh engineer with zero context beyond the repo and the PRD could implement the whole thing without asking a single question.** Until that's true, keep asking.

## Ground rules

- **Ask in maximal batches, not one at a time.** Each round, ask every question that is currently askable — i.e. every open question that does not depend on an unanswered one. The goal is to minimize round-trips: a grill should typically finish in 2–4 batches, not 15 single questions. Number every question (Q1, Q2, …) so the user can answer in shorthand ("Q1: a, Q2: yes, Q3: skip").
- **Batch by dependency, not by topic.** Only defer a question to a later batch if its wording or its answer genuinely depends on an earlier answer (e.g. verification depends on stack, task shape depends on scope). If a question can be asked now, ask it now — do not hold questions back to seem methodical.
- **Always provide your recommended answer** with each question, and say why in one line. Where the choice is enumerable, list 2–4 concrete options inline with the recommended one first, marked "(Recommended)". This lets the user answer a full batch quickly by mostly accepting or overriding recommendations.
- **No dodging inside batches.** Batches make it easy for the user to skip the hard questions. Track every unanswered or vague answer and re-ask it explicitly at the top of the next batch — a question is only closed when it has a usable answer or is confirmed irrelevant.
- **Facts are yours, decisions are the user's.** If the answer is discoverable — in the filesystem, the codebase, git history, package.json, existing docs, the web — look it up instead of asking. Only put actual *decisions* to the user: trade-offs, priorities, scope lines, taste.
- **Walk the tree in waves.** Answers open new branches; collect all newly opened branches from a batch's answers and put them into the next batch together. Track resolved vs. open decisions internally, and tell the user roughly how many open decisions remain at the top of each batch.
- **Relentless, not endless.** Every question must change what would be written in the PRD. When an answer wouldn't alter the spec, don't ask it. Trivial confirmations can be bundled into the final draft review instead of asked individually.
- **Do not write the PRD until the user confirms shared understanding.** No acting on partial answers.

## Procedure

### 1. Ingest and explore

Take whatever the user gives — a sentence, notes, a link, a rant. Before asking anything, explore the environment: the repo (stack, structure, conventions, existing tests and verification commands, similar features already implemented), and any referenced materials. Every question you ask after this must be one the environment could not answer.

### 2. Grill

Work through the coverage areas below in batches. **Batch 1 should be the biggest**: after exploration, ask every question from every coverage area that doesn't depend on another answer — typically most of areas 1–6 and 8 can go into the first batch. Later batches contain (a) follow-ups opened by earlier answers, (b) dependency-gated questions (e.g. verification once the stack is known, task shape once scope is fixed), and (c) re-asks of anything dodged or vague. Skip any area the exploration or earlier answers already settled.

Format each batch as a numbered list, grouped under short area headers, each question with its recommendation. End the batch with: "Answer inline by number — 'agree' accepts my recommendation."

Coverage checklist — the PRD cannot be written until each of these is either resolved with the user or confirmed irrelevant:

1. **Goal & motivation** — what exists when done, for whom, why now. What does success look like in one sentence?
2. **Definition of done** — checkable, not arguable. What would make the user say "ship it"?
3. **Scope line** — the sharpest questions live here. What is explicitly OUT? What's the smallest version that's still worth doing? What will the user regret not excluding?
4. **Users & flows** — who touches this, the 2–3 flows that must work end to end, what happens on the unhappy paths.
5. **Technical decisions** — stack choices not already dictated by the repo, data model, integration points, migrations, backwards compatibility. Only the ones that are genuine decisions.
6. **Quality bar & constraints** — performance, security, privacy, accessibility, i18n: which of these actually matter here, and how much?
7. **Verification** — what command proves an iteration is correct? If the project has none, what minimal gate (test, type check, smoke script) should exist first? A PRD without a verification command is not done.
8. **Risks & unknowns** — what could invalidate the plan? Anything the user is assuming that should be checked before the loop burns iterations on it?
9. **Task shape** — rough ordering and sizing sanity check: does the user agree with what's foundational, and is anything a research task rather than a build task?

Challenge weak answers. "Both options" is usually a dodge — ask which one wins when they conflict. Vague adjectives ("fast", "clean", "simple") get converted into something checkable or dropped. If the user says "you decide", make the decision, state it, and record it as decided — but confirm the ones with real consequences.

### 3. Confirm shared understanding

Before writing anything, play back a compact summary of every decision made (grouped, not a transcript) and ask: "Is this the spec? Anything missing or wrong?" Iterate until the user says yes.

### 4. Write the PRD

Write `PRD.md` at the project root using the `ralph-loop-arm` template shape: Goal, Definition of done, Verification, Context, Tasks (one-iteration-sized `- [ ]` checkboxes with acceptance criteria, foundational-first), Out of scope, Notes. Every task must trace back to a grilled decision — nothing invented, nothing left vague. Show it to the user.

### 5. Offer the handoff

If this is a project where the loop makes sense, offer to arm it: initialize `progress.txt` and continue with the `ralph-loop-arm` skill (Phase 2 — Arm). If the user only wanted the spec, stop there.

## Anti-patterns

- Asking questions the codebase already answers. Explore first, always.
- Drip-feeding one question per turn. Every round-trip costs the user time — if a question could have gone in the current batch, holding it back is a failure.
- Cramming two decisions into one question. Batches are many questions, but each question is still exactly one decision.
- Letting batch answers slide: accepting "Q4: whatever works" without re-asking it as a concrete choice in the next batch.
- Accepting scope creep silently — every "oh and also..." gets a "in this PRD, or out?"
- Padding the interview to seem thorough after the tree is actually resolved.
- Writing tasks the user never discussed. The PRD is the interview's minutes, not your invention.
