# Ralph Reference

**From a conversation to shipped code in three steps: capture context, grill it into a PRD, hand the PRD to an autonomous Ralph loop.**

This repository documents Eugen's development process with [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and ships everything needed to replicate it: the three Claude Code skills, the loop runner, the templates, and the background reading. Clone it, run `./setup.sh`, and the same workflow is available in any of your projects.

## The process at a glance

Round 1 starts from a conversation, because nothing exists yet:

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

Every round after that starts from feedback about something that already runs, and goes
through work items instead of a grill:

```
 1. FEEDBACK                2. WORK ITEMS              3. PRD            4. RALPH LOOP
 ─────────────              ─────────────              ─────────────     ─────────────
 Chat export, emails,  ──▶  /feedback-to-todos    ──▶  /ralph-loop-arm ──▶ same loop,
 meeting notes, bug         investigates each          orders them into    one task per
 reports                    group in the code and      a thin PRD that     iteration
                            writes one ticket each     points at each file
 Output: raw batch          Output: ToDos/*.md         Output: PRD-ROUND<n>.md
```

| Step | What you do | Tool | Output |
|---|---|---|---|
| 1. Context | Talk the idea through, record it, export the transcript | Any recorder or transcription tool | `context/<date>-<topic>.md` |
| 1'. Feedback | Drop the raw feedback in front of Claude | `/feedback-to-todos` skill | `ToDos/FEAT-nn.md`, `ToDos/BUG-nn.md` |
| 2. PRD | Answer one batch of real decisions, confirm the playback | `/prd-grill` (round 1) or `/ralph-loop-arm` work-item mode (round 2+) | `PRD.md` or `PRD-ROUND<n>.md`, progress log |
| 3. Ralph loop | Approve the PRD, arm the loop, launch it, review in the morning | `/ralph-loop-arm` skill, `.ralph/loop.sh` | Commits on `loop/<slug>` |

The guiding idea: **the spec is the steering wheel**. Human effort goes into steps 1 and 2.
Step 3 is unattended, and the quality of what comes out is the quality of the PRD that went in.

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

# 2'. ...or, for a project that already runs, start from the feedback instead
> /feedback-to-todos @feedback/2026-09-10-users.md
> /ralph-loop-arm write the PRD from the ready work items

# 3. When the PRD is approved, arm and launch the loop
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
3. Leave unknowns in the *Open questions* section. Step 2 exists to resolve them, and it writes the answers back into this file under *Decisions taken* so the next round does not re-ask them.
4. Optional, and cheap: clone anything that shows what "good" looks like into `context/` and list it under *Reference material* — an open-source project solving a similar problem, a competitor's public docs, an internal repo with the pattern you want copied. The grill reads them. It is the single easiest way to raise the quality of what comes out.

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
- **Only asks what is genuinely yours to decide.** A question reaches you only if it is a scope fork with materially different outcomes, a product or commercial trade-off, or a one-way door. Everything else it settles from the code and shows you in the playback, where you can overrule it. A wall of questions is a bug in the filter, not thoroughness.
- **Covers a fixed checklist.** Goal, definition of done, scope line, users and flows, technical decisions, quality bar, verification command, risks, task shape. Nothing gets written until each is resolved or confirmed irrelevant.
- **Plays the spec back** and asks "is this it?" before writing anything.
- **Writes the answers back into the context brief** before writing the PRD: each resolved question becomes a dated line under *Decisions taken* and disappears from *Open questions*. The brief stays the single point of truth — a decision that lives only in the PRD is gone the moment the next round writes a new one, and you get asked the same thing twice.
- **Writes `PRD.md`** in the shape the loop expects (`skills/ralph-loop-arm/templates/PRD.md`): goal, definition of done, verification, context, findings, attitude, one-iteration-sized `- [ ]` tasks with acceptance criteria, out of scope, notes.

Two of those sections carry more weight than their size suggests:

- **Findings** — what the grill traced in the code, with `file:line`. Every fact written down here is a search no iteration has to repeat. It is the cheapest token saving in the process.
- **Attitude** — the two to four standing decisions, each with its why, that an iteration checks its own choices against when the PRD does not spell something out. It is what stops a loop drifting task by task. Keep it under four lines; longer and it becomes a style guide and gets skimmed.

The bar for done: a fresh engineer with zero context beyond the repo and the PRD could implement everything without asking a single question.

**Two grilling skills, two jobs.** `prd-grill` produces the PRD. `grill-me` is its lighter sibling: a one-question-at-a-time interview that stress-tests a plan or thesis and produces no document. Use `grill-me` when the idea is still fuzzy and you want your assumptions surfaced; move to `prd-grill` when you are ready to commit to a spec. Both are in `skills/`.

## Step 2': Feedback into work items, for every round after the first

Once something is running, the input stops being a conversation and becomes feedback: a
chat export, an email thread, meeting notes, a list of complaints. Grilling from scratch is
the wrong tool for that — it re-derives context the code already holds. Run this instead:

```
claude
> /feedback-to-todos @feedback/2026-09-10-users.md
```

What `feedback-to-todos` does:

- **Groups the feedback by the code seam it touches**, not by who said it. Three people
  complaining about one slow page is one item; one person listing five annoyances is five.
- **Investigates each group in the code** in parallel, then fact-checks each draft against
  the code before writing it.
- **Writes one file per group**, `ToDos/FEAT-nn-slug.md` or `BUG-nn-slug.md`, each carrying
  the verbatim feedback with its date and author, how the code works today with `file:line`,
  a root cause for bugs, a plan, acceptance criteria and the repo's real verification
  command.
- **Numbers them from files and git history together.** Shipped items get archived while
  their ID lives on in commit messages, so the folder alone is not a reliable maximum.

The bar is the same one the PRD has to clear, applied per file: someone picks up any single
item cold and implements it, without re-reading the feedback thread and without re-exploring
the codebase.

Then hand the ready items to the loop skill:

```
> /ralph-loop-arm write the PRD from the ready work items
```

It resolves whatever open questions the items still carry in one batch, writes each answer
back into its file, orders the tasks by dependency, and produces a PRD that is only an
ordering layer: one thin task per item, pointing at the file.

**The work item is the contract.** The PRD owns order, dependencies and the loop contract.
Implementation detail lives in the ticket, in one place. That is what makes a PRD cheap to
rewrite every round — and the work items, unlike the PRD, survive from one round to the next
as the project's actual backlog.

## Step 3: Arm and run the Ralph loop

[Ralph](https://ghuntley.com/ralph/) is a loop that runs a fresh Claude Code session against the same prompt again and again. Each run reads `PRD.md` and `progress.txt`, picks exactly one unchecked task, implements it, runs the verification command, commits, and stops. The next run continues from that commit.

**Arm** (once per PRD), inside Claude Code:

```
> /ralph-loop-arm arm the loop
```

This creates `.ralph/` in the project with `loop.sh`, the two prompts (`iteration.md`, `reviewer.md`), and a `config.env`:

```
BRANCH=loop/<slug>
PRD_FILE=PRD.md               # or PRD-ROUND7.md
PROGRESS_FILE=progress.txt    # or progress-r7.txt
MAX_ITERATIONS=50             # about 2x the task count
REVIEW_EVERY=5
# ALT_MODEL=claude-fable-5    # optional per-task routing, off while empty
# ALT_TAG="(fable)"   # quote it: unquoted parentheses are a bash array
```

It commits the PRD, the progress log, and `.ralph/` and adds `.ralph/logs/` to `.gitignore`.

**Which files a round uses.** Arming detects the layout rather than assuming one. A repo
using `PRD-ROUND<n>.md` + `progress-r<n>.txt` gets the next number and its earlier rounds are
left untouched — they are the history of what was decided when. A flat repo keeps `PRD.md` +
`progress.txt`, and a finished round is archived to `PRD-archive-<date>.md` first. A new round
never appends to a used progress log: the runner reads the whole file for its sentinels, so a
stale `LOOP_COMPLETE` would stop the new loop on iteration one. The runner refuses to start in
that state rather than burning a night on it.

**Per-task model routing** is off unless you ask for it. With `ALT_MODEL` set, a task tagged
`(fable)` runs on that model and everything else runs on the default; the commit trailer names
whichever model did the work, so `git log` stays honest. Reserve the tag for work that must be
right first time — architecture, contracts, core state machines, load-bearing algorithms.
Tagging half the PRD defeats the point and spends the usage limit before morning. Reviewer
passes always run on the default model.

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

**Check on it**, in Claude Code: `> /ralph-loop-arm loop status`. Or by hand: the progress log is the narrative, `git log --oneline loop/<slug>` should show one commit per iteration, and `.ralph/logs/` has one log per run.

**Morning routine:** read the progress log top to bottom, skim the commits, run the app, then merge or open a PR from the loop branch. Objections and blockers in the log tell you where the spec was unclear. Fix the PRD, not the code, and re-run.

## What is in this repository

```
README.md                          this document
setup.sh                           installs skills/ into ~/.claude/skills
skills/
  grill-me/                        one-question-at-a-time plan stress-test (no output file)
  prd-grill/                       batched interview that writes PRD.md
  feedback-to-todos/               raw feedback into one work-item file per request
    templates/work-item.md         the ticket shape the PRD points at
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
  PRD-TEMPLATE-multi-round.md      the multi-round PRD conventions in full
examples/
  afk-ralph-multi-round.sh         standalone runner for the multi-round variant
```

## Principles behind the process

Distilled from `docs/Context-Engineering.md` and from running loops:

- **Intent, references, invariants. Not step-by-step instructions.** The model owns the *how*. Point tasks at the files, specs, and fixtures they need instead of describing the code to write.
- **One task per iteration.** Small commits, easy review, and a bad iteration costs one commit rather than the project.
- **A verification gate is non-negotiable.** Never arm a loop without a command that must pass before commit. If the project has none, the first task is to create one.
- **Explicit out-of-scope.** The loop will expand into anything not fenced off.
- **Decisions belong to the human, facts belong to the agent.** The grill only asks what the repo cannot answer, and never resolves a judgement call silently.
- **Decide, don't ask.** Only three things are worth a question: a scope fork with materially different outcomes, a product or commercial trade-off, a one-way door. Everything else gets settled and shown in the playback. A wall of questions is a failure, not diligence.
- **Write the answer back where the question lived.** A resolved decision goes into the context brief or the work item, not only into the PRD. Otherwise the next round asks it again.
- **The work item is the contract.** Where tickets exist, the PRD owns order and dependencies and nothing else. Detail lives in one place, so nothing drifts, and the PRD stays cheap to rewrite each round.
- **Record what you traced.** A `file:line` in Findings is a search fifty iterations do not repeat.
- **Fix the spec, not the output.** When the loop goes wrong, the PRD was unclear. Edit it and run again.

## Rounds

A project that keeps going turns one PRD into a sequence: `PRD-ROUND1.md`, `PRD-ROUND2.md`, each with its own progress log, each arming its own branch. Arming handles the numbering and leaves earlier rounds alone, and per-task model routing works the same way in both layouts, so this is no longer a separate variant of the process — it is the same process on its second night.

Start flat. Switch to numbered rounds when you want the history of what each night decided to stay readable, which in practice is around the third round.

`docs/PRD-TEMPLATE-multi-round.md` holds the fuller conventions from a project that ran this way — findings, attitude, per-round surfaces and budgets — and is worth reading once. `examples/afk-ralph-multi-round.sh` is a standalone runner from the same project, kept for reference; the supported runner is `.ralph/loop.sh`.

## Further reading

- Geoffrey Huntley, [Ralph](https://ghuntley.com/ralph/), the original technique
- Matt Pocock, [Getting Started With Ralph](docs/Ralph.md) and [11 tips for AI coding with Ralph](https://www.aihero.dev/tips-for-ai-coding-with-ralph-wiggum)
- Anthropic, [The New Rules of Context Engineering for Claude 5 Generation Models](docs/Context-Engineering.md)
- Matt Pocock, [skills](https://github.com/mattpocock/skills), origin of the `grill-me` idea
- [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code)

## Credits

The Ralph technique is Geoffrey Huntley's. `docs/Ralph.md` is Matt Pocock's guide, reproduced for offline reading. `docs/Context-Engineering.md` is an Anthropic engineering post by Thariq Shihipar. The `grill-me` skill is adapted from Matt Pocock's skills repository. Skills, runner, and templates in this repository were developed by Eugen with Claude Code.
