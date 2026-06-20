# Chapter 5 — The human loop

*Layer 3 — freed from typing, you improve the harness.*

Chapters 3 and 4 built a machine that builds and remembers. This chapter is about
what you do now that it does. The honest answer is: **the most important part** —
the part the machine structurally cannot do.

The governing line comes from Andrej Karpathy: *"you can outsource your thinking
but you can't outsource your understanding."* It draws a sharp boundary:

- **Verifiable work → outsource it freely.** Syntax, API recall, implementation
  mechanics. The model is superhuman here. Spending your attention on it is
  waste.
- **Unverifiable work → you must own it.** Whether this is the right thing to
  build, whether the abstraction is sound, whether the edge cases are handled for
  good reasons, whether the UX feels right. Errors here are subtle and don't
  announce themselves — exactly where your understanding has to be load-bearing.

The harness took the first category. The human loop is you, deliberately working
the second. It has four phases, and they form a closed cycle:

```
   Understanding ─▶ Strategy ──▶ Intent ─▶ [ the harness builds ] ─▶ Evaluate
   build your model  sharpen the  express      Chapters 3 & 4         walk it, run it,
   of the problem    vision; pick what to                            judge it, and
   space             metric + bet build                              measure the outcome
        ▲                 ▲                                                │
        │                 └────────── did the bet move the metric? ───────┤
        └───────────────────── evaluating deepens understanding ──────────┘
```

The middle two phases pair up as front-and-back bookends: **Strategy** sets a
metric and a bet; **Evaluate** measures whether the bet moved it. **Intent**
expresses one feature; **Evaluate** judges whether it was built right. Two
expressions of intent at two altitudes, each with its own check.

## The two loops interlock

The human loop and the machine loop aren't parallel tracks — they feed each
other, and that coupling is the design:

> **Your loop's output is the harness's input. The harness's output is your
> loop's input.**

You produce intent (a PRD); the harness consumes it and produces a pull request;
you consume that PR by evaluating it; what you learn sharpens the next intent.
Neither loop is complete without the other. The machine exists to serve your
loop — and naming your loop explicitly is what keeps *your* job legible as the
machine takes over more of the typing.

Each phase is a built skill.

## Understanding — `/wiki-init`

Before you can express good intent, you need a real model of the problem space:
the domain, the prior art, the constraints, the trade-offs. The Understanding
phase builds *your* model, not the agent's.

[`/wiki-init`](../skills/human-loop/wiki-init/SKILL.md) stands up a
standalone, LLM-maintained knowledge base in the shape of **Karpathy's "LLM
Wiki"**: rather than retrieving and re-synthesizing on every question, you
synthesize **once, at ingest time**, into durable, cross-linked pages that
compound as sources accumulate. You curate sources and ask questions; the LLM
does the bookkeeping humans abandon wikis over — updating cross-references,
reconciling pages, keeping the map current.

This wiki is deliberately **not** a project artifact, and that's the bright line
worth holding:

- The **wiki** is cross-project **domain and architecture** knowledge, written to
  be read **by you**. It lives in its own repo, outside any codebase.
- The **Expert** (Chapters 2 & 4) is per-project **code** memory, written to be
  read **by agents**.

The payoff is direct: a richer model of the domain means a sharper strategy. You
arrive at the next phase already understanding the concepts, the constraints, and
the trade-offs — so the bet you place is the right one.

## Strategy — `/roadmap-init`, `/roadmap`, and `/evaluate-outcome`

Understanding gives you a model of the problem space. Strategy is where you turn
that model into a **direction with a way to know it's working.** This is the phase
that keeps the whole loop out of the *build trap* — measuring success by features
shipped rather than outcomes produced. A roadmap that's just a list of features
with dates is the trap wearing a costume; the cure is to express direction as
**bets on outcomes you can measure.**

### `/roadmap-init` — stand up the home (once)

Strategy needs a place to live, and standing it up is a one-time, mechanical job —
so it's its own skill, exactly as Understanding splits `/wiki-init` from `/ingest`.
[`/roadmap-init`](../skills/human-loop/roadmap-init/SKILL.md) scaffolds the **roadmap
home**: the `AGENTS.md` that teaches the taxonomy and folder conventions (written
once; the folder tree is the map) and the nested `backlog/AGENTS.md` that holds the
work-item schema — the single source of truth every downstream skill defers to. It
also installs the recurring `/roadmap` skill into the home repo and points that
repo's root `AGENTS.md` at it, so the home carries its own operating skill the way a
wiki vault carries its `/ingest`. It writes **no** strategy content — no vision, no
bet, no metric. That's the next skill's job.

### `/roadmap` — sharpen the vision into a measurable bet

[`/roadmap`](../skills/human-loop/roadmap/SKILL.md) is the human-attentive
conversation that *fills* the home, the upstream sibling of `/intent` and run as
often as you place a new bet. Inside the home `/roadmap-init` stood up, it writes
per-vision folders, each holding a few coupled things:

- the **vision**, sharpened — narrative direction, the act of writing it tightens it;
- the **strategic intent** — the chosen focus and its **lagging outcome** (the slow
  metric: retention, revenue), with an **instrument** (where the number lives) and a
  **baseline** taken by running the probe against the live world *right now*;
- the **current bet** — one *problem*, stated as a falsifiable hypothesis that moves
  a fast **leading** indicator believed to feed the lagging outcome, plus a loose list
  of **candidate bets**. There is no single "North Star metric" to crown — a
  vision runs on a small portfolio of leading and lagging signals;
- a **unified backlog** — the concrete work (features + bugfixes) that serves the bets.
  A backlog item carries *no* metric (if it does, it's a bet); it may link up to the bet
  it serves, so "all work for a bet" is an Obsidian/Dataview query, not a folder.

Its discipline is the mirror of `/intent`'s "failing for the right reason." Where
the PRD runner forces *done is executable*, the roadmap forces *impact is
measurable*: the conversation isn't finished until the metric has been read. A
product owner who can name the metric, its instrument, and a baseline knows what
they want; one who hands over a feature list and a deadline often doesn't. As with
`/intent`, **ending with no artifact is a valid outcome** — sometimes you just
needed to think the vision out loud.

Two altitudes meet here, and keeping them apart is load-bearing: the **bet** is the
unit of *outcome* (one metric, measured once it ships), and it decomposes into one
**or many PRDs** — the unit of *output* (each with its own runner). `/roadmap`
names the problem; it does **not** pre-slice it into features. That slicing is
`/intent`'s job, done lazily, one bet at a time. The metric lives on the bet, never
on a PRD — welding a lagging, real-world number onto a deterministic pre-merge
runner would break the line the whole harness rests on.

The features and bugfixes that serve a bet live in the home's **unified backlog** — the
*options* a bet spends to move its indicator. This is where "Escaping the Build Trap" earns
its keep: defining features to serve a bet is not the trap; the trap is mistaking a shipped
feature list for a moved outcome. So the structure encodes the rule plainly — **a bet is done
when its metric is read, not when its backlog empties.** The home is an Obsidian vault
(frontmatter + `[[wikilinks]]`), and the loop closes both ways: `/intent` **registers the PRD
it builds back** onto its backlog item, so output is always traceable to the outcome it's
meant to move.

For a single-repo product the roadmap home is a `roadmap/` folder beside `prds/`;
for a product spanning repos (a UI repo, an API repo) it is its **own repo**, above
any one codebase — the same standalone shape as the Understanding wiki. Builds fan
out per-repo through normal `/intent` PRDs; **outcomes converge** at one bet-level
metric. The machine gains nothing to coordinate across repos — all cross-repo
sequencing lives here, in the human loop.

### `/evaluate-outcome` — measure whether the bet worked

The back bookend, and the mirror of `/roadmap`. Once a bet has shipped end-to-end,
[`/evaluate-outcome`](../skills/human-loop/evaluate-outcome/SKILL.md) **re-runs the
probe** `/roadmap` authored — synthesize once, read many — appends the reading to an
append-only log, and reads the **trajectory** against the hypothesis over the
declared horizon. It is described more fully under Evaluate below; what matters
here is that it closes the Strategy loop: its verdict (confirmed / flat /
inconclusive / regressed) flows back to sharpen the next bet. This is the **measure**
step that upgrades the whole human loop from *build → evaluate* to *build →
**measure** → learn* — the part that proves a shipped feature actually mattered, not
just that it was built.

## Intent — `/intent`

This is the front bookend, and you met it in Chapter 3 as the harness's entry
point. From the human loop's side, [`/intent`](../skills/human-loop/intent/SKILL.md)
is where understanding becomes a buildable thing. Its discipline is worth
restating because it's where your thinking does its work:

- **Elicit outcomes, not solutions.** People arrive describing a solution ("add a
  `/api/search` endpoint"); the job is to surface the *need* underneath ("readers
  can't find a post by title") and the observable outcome that would satisfy it.
- **"How would we know that's true?"** is the throughline. Asked of every desired
  outcome, it converts a wish into both a sharp prose criterion *and* a concrete
  check — the two coupled artifacts (`prd.md` + `run-prd-test.sh`) born together.
- **You don't write the runner; the Expert drafts it, you review.** This keeps
  verification grounded in how the project actually works, not your instinct in
  the moment.

`/intent` is a *coordinator, not a knowledge holder* — the domain reasoning comes
from the Expert. Your contribution is the understanding and the bet from the
previous phases, and the judgment about what's worth building. When the feature
serves a roadmap **bet or backlog item**, `/intent` reads it (you pass the home's path
inline) and lets its problem and metric sharpen the PRD's *why* — but the metric stays
rationale, never a runner check — then **registers the PRD back** onto that item so the
build traces to the outcome. Confirm the PRD, and the machine takes it from there.

## Evaluate — `/evaluate-pr`, `/evaluate-sessions`, and `/evaluate-outcome`

The back bookend, and the mirror of `/intent` (and, for the third skill, of
`/roadmap`). The harness hands you a finished PR; evaluation is where you do the
unverifiable work the machine couldn't. There are three skills, because there are
three things to evaluate: *what* was built, *how* it was built, and *whether it
mattered*.

### `/evaluate-pr` — evaluate *what was built*

[`/evaluate-pr`](../skills/human-loop/evaluate-pr/SKILL.md) produces two
outcomes. The tangible one: merge, fix-and-push, or close. The intangible one —
**the one that matters more** — is *you* understanding the change deeply enough
to defend every scenario and design decision in it.

That intangible output is the literal mechanism that closes the loop back to
Understanding and sharpens the next Intent. So the skill is a teacher and a taste
partner, not a second linter: the bot reviewer already caught the mechanical
defects, so it *ingests* those findings and sets them aside, then spends your
attention on what a bot structurally can't judge — is this simpler than it could
be, is the abstraction sound, does the UX feel right? It runs the system with
you, walks the definition-of-done scenarios live, and probes Socratically rather
than lecturing. The understanding gate is soft but real: it ends on "do you feel
you understand this change?" and skipping the walk-through is an explicit
opt-out, never a silent rubber-stamp.

If the walk surfaces something to change, **you fix it here and push** — you
never hand work back to the loop. You are the last mile. And if it surfaces necessary
work that's *out of scope* for this PR — a missing-but-obvious feature, a bug to fix
later — and a roadmap home is present, you file it into that home's **backlog** with the
human, where the next `/roadmap` or `/intent` pass will pick it up.

### `/evaluate-sessions` — evaluate *how it was built*

[`/evaluate-sessions`](../skills/human-loop/evaluate-sessions/SKILL.md) is
where the human loop reaches back and improves the harness itself. The harness
posts the full `claude -p` build trail on every PR — the sessions the agents ran.
This skill reads that trail *with you* to find where the project's context served
the agents and where it failed them: where an agent re-derived something the
Expert should have told it, followed a stale `AGENTS.md` pointer, or guessed
because a spec was thin.

What you find turns into two durable outcomes — the **flywheel**:

> *Observe a trace → capture it as an eval → fix the context → it persists as a
> regression test.*

- **Evals** — when a session shows a skill behaved well or badly *given the
  context it had*, freeze that as a runnable check under `evals/`. An eval is a
  regression test over the harness's **own skills and context** (the analog of
  testing a prompt), distinct from the PRD runner, which tests the product.
- **Context fixes** — when a piece of context misled an agent, fix the Expert
  shard, the `AGENTS.md` pointer, or the skill.

This is the moment the framing of the whole book becomes literal: every PR the
harness builds is a graded trial of your project's context, and every eval you
capture makes the project a little better at building itself next time. You're
not auditing one PR — you're **tuning the harness.**

### `/evaluate-outcome` — evaluate *whether it mattered*

The two skills above judge the PR. [`/evaluate-outcome`](../skills/human-loop/evaluate-outcome/SKILL.md)
judges the **bet** — one altitude up, and weeks later. Once a bet has shipped
end-to-end (which, for a multi-repo bet, only *you* can confirm), it re-runs the
probe `/roadmap` authored, appends a reading, and reads the **trajectory** against
the hypothesis over the declared horizon.

Two disciplines make it honest. First, **never a single point**: a reading two days
post-ship is noise — novelty spikes regress, the world is loud — so a blip is not an
outcome; you read the *shape* across the horizon, or you keep sampling and say "too
early." Second, **advisory, never a gate.** Unlike `run-prd-test.sh`, which the
dispatcher will not merge past (Invariant 8), the metric is measured in the world,
after merge, over time — the machine structurally *cannot* enforce it. This is the
system's first deliberately **unenforceable** contract, and that's exactly right:
the metric is the canonical *unverifiable* thing, so it belongs entirely to you. A
flat or inconclusive verdict is a real, valuable result — the learning the next bet
is built on — not a failure to dress up. The verdict flows back to `/roadmap`, and
the loop's slowest, most important question — *did the thing we shipped actually
move the outcome we cared about?* — finally has a home.

## Memory still has one write path

Notice what evaluation does *not* do: it doesn't write memory directly. Whatever
you learn here isn't ground truth yet, because the change isn't merged yet. So
the insight either becomes a pushed fix that rides into `main` — where `/learn`
(Chapter 4) picks it up as ground truth to extend, not second-guess — or it lives
in your head and sharpens the next Intent. Evals and context fixes land on a
branch and reach memory the same way: through a merge. The single write path of
Chapter 4 holds. You may now *seed* memory deliberately; you still never bypass
the door.

## Where you steer

You touch the **machine** at exactly three points — and every one of them is a
moment in this loop:

| You... | Human-loop phase | What it does to the machine |
|---|---|---|
| Confirm a PRD | end of **Intent** | starts the build |
| Evaluate and merge a PR | **Evaluate** | ends the build; triggers `/learn` |
| Unstick a STUCK feature | a forced detour into **Evaluate** | corrects the context, then merges |

The Strategy phase adds two more touchpoints — but they're a different *kind*, and
the difference is the point. They steer your **direction**, and they do nothing to
the machine at all:

| You... | Human-loop phase | What it does |
|---|---|---|
| File a roadmap + bet, with a metric and a baseline | **Strategy** (`/roadmap`) | sets the direction and how you'll know it worked — the machine never reads it |
| Judge whether a shipped bet moved its metric | close of **Strategy** (`/evaluate-outcome`) | reshapes the next bet — advisory, gates nothing |

That second table is the *unenforceable* half on purpose. The metric is the
canonical thing the machine can't verify — measured in the world, after merge, over
time — so steering by it is entirely yours. Everything between all of these
touchpoints is the machine. Everything *at* them is judgment — yours.

---

So here's where we've arrived. The project plans, implements, verifies, and
remembers on its own. You spend your time understanding the problem, setting a
direction you can measure, expressing intent, and evaluating outcomes — and when
you evaluate, you don't just approve work, you improve the thing that produced it
and learn whether it moved the needle you set.

That's not a new workflow bolted onto coding. It's a different relationship to
your own project. Worth saying plainly, because it's the whole point.

→ [Chapter 6 — The mindset shift](./6-the-mindset-shift.md)
