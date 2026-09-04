# PRD conventions & template

A PRD is one Ralph round: a commit-sized task list derived from one or more specs in
`specs-and-more/specs/`. The specs stay the source of intent; the PRD is the work order.
Name PRDs `ralph/PRD-<nn>-<slug>.md`; the loop scripts create the matching
`PRD-<nn>-<slug>.progress.txt` beside it and both get committed as they change. A task
closes in two commits: the work (with the PRD box ticked), then the progress line naming
that commit's sha. Never amend to merge them — the line's sha would go stale.

Writing rules (the context-engineering short version): give intent, references and
invariants — never step-by-step instructions; the model owns the HOW. Point every task at
the spec sections, files and fixtures it needs (rich references beat prose). Don't restate
what CLAUDE.md or the specs already say. If pre-round investigation happened, write the
findings down with `file:line` so no iteration searches twice.

## Model routing

`claude-opus-5` is the default and needs no tag. Tag a task `(fable)` to run it on Claude
Fable 5 — reserve it for work that must be thought through once and right: architecture
and package boundaries, contracts design, core state machines and loops, load-bearing
algorithms (elo, veto, drop weighting), gnarly cross-cutting debugging. Mechanical
follow-ups and page work stay on Opus.

## Template

    # PRD <nn>: <round title>

    <2–5 sentences: the user-visible outcome of this round and why now. Which specs it
    draws on.>

    **Branch:** `<branch>` (from `main`). **Surface:** <folders this round may touch>.
    **Model:** `claude-opus-5`; tasks tagged `(fable)` run on Fable 5.
    <standing budgets when relevant: "exactly one additive migration, in T2", deploy
    rules, feature-flag expectations.>

    ## Findings

    <Only if investigation preceded the round: the traced chain with file:line, what
    already exists to reuse. Delete the section when empty.>

    ## Attitude

    <The 2–4 standing decisions that keep every task honest this round, each with its
    why. These are the lines an implementer checks their choices against.>

    ## Tasks

    - [ ] **T1 (fable): <title>.** <What done looks like. References: spec §, files,
      fixtures, design-references routes.>
    - [ ] **T2: <title>.** <…>

    ## Working rules

    <Round-specific verification beyond CLAUDE.md's defaults; budgets; hard don'ts.>

    ## When the PRD is complete

    <The final sweep: docs to update, flags to flip, a demo path to walk. The loop
    outputs the completion sigil after this.>
