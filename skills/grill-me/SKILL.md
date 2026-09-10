---
name: grill-me
description: Run a relentless, one-question-at-a-time interview that stress-tests a plan, design, decision, memo, or deal thesis until every open branch is resolved and the user and Claude share the same understanding. Trigger whenever the user says "grill me", "/grill-me", "grill this", "interview me", "stress-test this plan", "poke holes in my thinking", "pressure-test this", "challenge me on this", "was übersehe ich", "löcher in meinen plan", or otherwise asks to be interrogated about a half-formed plan before committing to it. Also trigger when the user presents a rough plan and asks to have its assumptions surfaced rather than asking for a written deliverable. Do NOT use when the user wants a finished artifact (memo, spec, PRD, decision paper) — that is a different skill.
---

# Grill Me

A stateless interview that hardens a plan before it is executed. It produces no
document — the only output is a sharpened, shared understanding in the
conversation itself.

Adapted from Matt Pocock's `grill-me` / `grilling` skills
(github.com/mattpocock/skills).

## The mental model

Every plan is a decision tree. Decisions depend on other decisions. The job is
to walk down that tree node by node, resolving each dependency before moving to
the ones that hang off it. An early answer often reshapes which questions come
next — which is exactly why questions must not be batched.

## Rules of the interview

1. **One question at a time.** Ask a single question, then stop and wait for the
   answer. Never present a list. A batch of parallel questions destroys the
   dependency ordering and overwhelms the user.
2. **Always attach a recommended answer.** With every question, state what you
   would choose and why, in one or two lines. The user should be reacting to a
   proposal, not staring at a blank page.
3. **Look it up before you ask it.** If a fact is discoverable from the
   environment — files, the repo, tools, connected systems, earlier messages —
   go and find it. Only genuine decisions get put to the user.
4. **The decisions belong to the user.** Never resolve a judgement call on their
   behalf, and never quietly assume one to keep moving.
5. **Be relentless, not agreeable.** A vague, hand-wavy, or internally
   inconsistent answer gets pushed on again rather than accepted. Keep going
   until the branch is genuinely closed.
6. **Depth before breadth.** Follow one branch to its end, then return to the
   trunk. Do not hop between unrelated topics.
7. **Do not start building.** No implementation, no drafting, no deliverable
   until the user confirms that shared understanding has been reached.

## Procedure

1. **Read the plan.** Take whatever the user brought — a paragraph, a doc, a
   deck, a repo, a half-thought — and map it into a decision tree. Do not show
   the tree; use it to sequence the interview.
2. **Open with the root decision.** The one that constrains the most downstream
   choices. Question + recommended answer.
3. **Descend.** After each answer, re-evaluate the tree. New branches appear;
   others become irrelevant. Ask the next question in dependency order.
4. **Probe the soft spots.** Priority targets:
   - Unstated assumptions presented as facts
   - Undefined terms that different people would read differently
   - Reversible vs. one-way-door decisions being treated the same
   - Success criteria that cannot be measured
   - Dependencies on people, systems, or approvals not yet secured
   - The failure mode the user is quietly hoping does not happen
5. **Close.** When no open branches remain, summarise the settled understanding
   in a short bulleted list and ask the user to confirm it. If they confirm,
   stop there and ask what they want to do with it.

## Boundaries

- **No artifacts.** This skill writes nothing to disk and creates no files. If
  the user wants the outcome written up afterwards, hand off — do not
  re-interview them.
- **Skip it for trivial or already fully-specified tasks.** An interview there
  is pure friction; say so and get on with the work.
- **Non-technical plans are in scope.** Investment theses, org changes,
  negotiation strategies, and personal decisions grill the same way as
  architectures.
