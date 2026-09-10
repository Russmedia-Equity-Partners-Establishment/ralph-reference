# Ralph Reference

**From a conversation to shipped code in three steps: capture context, grill it into a PRD, hand the PRD to an autonomous Ralph loop.**

This repository documents Eugen's development process with [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and ships everything needed to replicate it: the three Claude Code skills, the loop runner, the templates, and the background reading. Clone it, run `./setup.sh`, and the same workflow is available in any of your projects.

## The process at a glance

```
 1. CONTEXT                 2. PRD                          3. RALPH LOOP
 ─────────────              ─────────────                   ─────────────
 Record or transcribe  ──▶  /prd-grill interviews you  ──▶  /ralph-loop-arm installs
 a conversation about       in batches until the spec        .ralph/ and loop.sh; the
 the product or feature     is complete, writes PRD.md       loop ships one task per
                                                             iteration, verified and
                                                             committed, until done
 Output: context brief      Output: PRD.md + progress.txt    Output: a branch of commits
```

| Step | What you do | Tool | Output |
|---|---|---|---|
| 1. Context | Talk the idea through, record it, export the transcript | Any recorder or transcription tool | `context/<date>-<topic>.md` |
| 2. PRD | Answer batched questions, confirm the playback | `/prd-grill` skill (optionally `/grill-me` first) | `PRD.md`, `progress.txt` |
| 3. Ralph loop | Approve the PRD, arm the loop, launch it, review in the morning | `/ralph-loop-arm` skill, `.ralph/loop.sh` | Commits on `loop/<slug>` |

The guiding idea: **the spec is the steering wheel**. Human effort goes into steps 1 and 2. Step 3 is unattended, and the quality of what comes out is the quality of the PRD that went in.

## Quick start

```bash
# 1. Get the skills onto your machine (once)
git clone <this-repo-url> ralph-reference
cd ralph-reference
./setup.sh                 # copies skills/ into ~/.claude/skills

# 2. In the project you want to build in
cd ~/code/my-project
mkdir -p context
cp ~/ralph-reference/templates/context-brief.md context/2026-09-10-feature.md
#    ...paste the transcript, fill in the brief, then:
claude
> /prd-grill @context/2026-09-10-feature.md

# 3. When PRD.md is approved, arm and launch the loop
> /ralph-loop-arm arm the loop
# in a real terminal (not inside the Claude session):
nohup ./.ralph/loop.sh > .ralph/logs/runner.log 2>&1 &
```

Prerequisites: the `claude` CLI installed and authenticated, `git`, and a project with a verification command (tests, type check, build). Docker sandboxing is optional; see `docs/Ralph.md`.

## Step 1: Capture context

The process starts with a conversation, not a document. Talk through the product or feature with a colleague, or think aloud alone, and record it. Any tool that produces a transcript works: Wispr Flow, Granola, Fireflies, a phone voice memo plus Whisper.

Then:

1. Create a `context/` folder in the target project and save the raw transcript there as `<date>-<topic>-transcript.md`.
2. Copy `templates/context-brief.md` next to it and distil the transcript into it. Claude can do the distillation for you: `claude "read @context/<transcript> and fill in @context/<brief> from it"`.
3. Leave unknowns in the *Open questions* section. Step 2 exists to resolve them.

A good brief answers: what hurts today, what exists when this is done, who uses it, why now, what was deliberately parked, and which constraints are already decided. Raw transcripts alone are acceptable input for step 2, but a brief makes the interview shorter.

## Step 2: Turn context into a PRD

Inside the project, start Claude Code and hand it the context:

```
claude
> /prd-grill @context/2026-09-10-feature.md
```

What `prd-grill` does:

- **Explores the repo first.** Stack, structure, conventions, existing tests. It only asks what the environment cannot answer.
- **Asks in numbered batches, not one question at a time.** Each question comes with a recommended answer. Reply in shorthand: `Q1: agree, Q2: b, Q3: out of scope`. A grill typically finishes in two to four rounds.
- **Covers a fixed checklist.** Goal, definition of done, scope line, users and flows, technical decisions, quality bar, verification command, risks, task shape. Nothing gets written until each is resolved or confirmed irrelevant.
- **Plays the spec back** and asks "is this it?" before writing anything.
- **Writes `PRD.md`** in the shape the loop expects (`skills/ralph-loop-arm/templates/PRD.md`): goal, definition of done, verification, context, one-iteration-sized `- [ ]` tasks with acceptance criteria, out of scope, notes.

The bar for done: a fresh engineer with zero context beyond the repo and the PRD could implement everything without asking a single question.

**Two grilling skills, two jobs.** `prd-grill` produces the PRD. `grill-me` is its lighter sibling: a one-question-at-a-time interview that stress-tests a plan or thesis and produces no document. Use `grill-me` when the idea is still fuzzy and you want your assumptions surfaced; move to `prd-grill` when you are ready to commit to a spec. Both are in `skills/`.

## Step 3: Arm and run the Ralph loop

[Ralph](https://ghuntley.com/ralph/) is a loop that runs a fresh Claude Code session against the same prompt again and again. Each run reads `PRD.md` and `progress.txt`, picks exactly one unchecked task, implements it, runs the verification command, commits, and stops. The next run continues from that commit.

**Arm** (once per PRD), inside Claude Code:

```
> /ralph-loop-arm arm the loop
```

This creates `.ralph/` in the project with `loop.sh`, the two prompts (`iteration.md`, `reviewer.md`), and a `config.env`:

```
BRANCH=loop/<slug>
MAX_ITERATIONS=50      # about 2x the task count
REVIEW_EVERY=5
```

It commits `PRD.md`, `progress.txt`, and `.ralph/` and adds `.ralph/logs/` to `.gitignore`.

**Launch**, from a real terminal so it survives the Claude session ending:

```bash
nohup ./.ralph/loop.sh > .ralph/logs/runner.log 2>&1 &
```

**How the loop behaves:**

- Works on branch `loop/<slug>`. You review and merge in the morning.
- Every iteration is `claude -p` with a fresh context reading only the PRD and the progress file. One task, verify, commit, log.
- Every fifth iteration, and once more when the loop believes it is finished, an **adversarial reviewer** runs instead of a worker. It reads the diffs, re-runs verification, and un-ticks any task that does not survive its acceptance criteria, leaving a written objection for the next worker.
- The verification command is never weakened. No skipped tests, no loosened types. A red gate the worker cannot fix becomes a `BLOCKED` entry instead.
- Stops on `LOOP_COMPLETE` (all tasks ticked and survived final review), `LOOP_STUCK` (same task blocked twice), two consecutive crashed iterations, or `MAX_ITERATIONS`. An outcome banner prints in the terminal, and goes to Telegram if `~/.claude/ralph-loop.env` holds `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID`.

**Check on it**, in Claude Code: `> /ralph-loop-arm loop status`. Or by hand: `progress.txt` is the narrative, `git log --oneline loop/<slug>` should show one commit per iteration, and `.ralph/logs/` has one log per run.

**Morning routine:** read `progress.txt` top to bottom, skim the commits, run the app, then merge or open a PR from the loop branch. Objections and blockers in the log tell you where the spec was unclear. Fix the PRD, not the code, and re-run.

## What is in this repository

```
README.md                          this document
setup.sh                           installs skills/ into ~/.claude/skills
skills/
  grill-me/                        one-question-at-a-time plan stress-test (no output file)
  prd-grill/                       batched interview that writes PRD.md
  ralph-loop-arm/                  author, arm, and check status of a loop
    scripts/loop.sh                the runner installed into projects as .ralph/loop.sh
    prompts/iteration.md           what each worker run is told
    prompts/reviewer.md            what each adversarial review run is told
    templates/PRD.md               the PRD shape
    templates/progress.txt         the progress log shape
templates/
  context-brief.md                 step 1 template for distilling a transcript
docs/
  Ralph.md                         Matt Pocock's getting-started guide (background)
  Context-Engineering.md           Anthropic on context engineering for Claude 5 models
  PRD-TEMPLATE-multi-round.md      advanced: numbered PRD rounds with model routing
examples/
  afk-ralph-multi-round.sh         advanced: loop runner for the multi-round variant
```

## Principles behind the process

Distilled from `docs/Context-Engineering.md` and from running loops:

- **Intent, references, invariants. Not step-by-step instructions.** The model owns the *how*. Point tasks at the files, specs, and fixtures they need instead of describing the code to write.
- **One task per iteration.** Small commits, easy review, and a bad iteration costs one commit rather than the project.
- **A verification gate is non-negotiable.** Never arm a loop without a command that must pass before commit. If the project has none, the first task is to create one.
- **Explicit out-of-scope.** The loop will expand into anything not fenced off.
- **Decisions belong to the human, facts belong to the agent.** The grill only asks what the repo cannot answer, and never resolves a judgement call silently.
- **Fix the spec, not the output.** When the loop goes wrong, the PRD was unclear. Edit it and run again.

## Advanced variant: multiple PRD rounds

For larger projects the single `PRD.md` becomes a sequence of numbered rounds, `ralph/PRD-01-foundation.md`, `ralph/PRD-02-...`, each with its own progress file and branch, and individual tasks can be routed to a stronger model. See `docs/PRD-TEMPLATE-multi-round.md` for the conventions and `examples/afk-ralph-multi-round.sh` for the runner. Start with the single-PRD flow above; move to rounds when one PRD stops fitting in a night.

## Further reading

- Geoffrey Huntley, [Ralph](https://ghuntley.com/ralph/), the original technique
- Matt Pocock, [Getting Started With Ralph](docs/Ralph.md) and [11 tips for AI coding with Ralph](https://www.aihero.dev/tips-for-ai-coding-with-ralph-wiggum)
- Anthropic, [The New Rules of Context Engineering for Claude 5 Generation Models](docs/Context-Engineering.md)
- Matt Pocock, [skills](https://github.com/mattpocock/skills), origin of the `grill-me` idea
- [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code)

## Credits

The Ralph technique is Geoffrey Huntley's. `docs/Ralph.md` is Matt Pocock's guide, reproduced for offline reading. `docs/Context-Engineering.md` is an Anthropic engineering post by Thariq Shihipar. The `grill-me` skill is adapted from Matt Pocock's skills repository. Skills, runner, and templates in this repository were developed by Eugen with Claude Code.
