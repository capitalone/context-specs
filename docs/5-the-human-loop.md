# Chapter 5 — The human loop

*Freed from typing, you improve the harness.*

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
the second. It has three phases, and they form a closed cycle:

```
   Understanding ──▶ Intent ──▶ [ the harness builds ] ──▶ Evaluate
   build your model    express        Chapters 3 & 4        walk the result,
   of the problem      what to                              run it, judge it,
   space               build                               improve the context
        ▲                                                        │
        └──────────── evaluating deepens understanding ──────────┘
```

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

The payoff is direct: a richer model of the domain means a sharper `/intent`. You
arrive at the next phase already understanding the concepts, the constraints, and
the trade-offs — so the feature you ask for is the right one.

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
from the Expert. Your contribution is the understanding from the previous phase
and the judgment about what's worth building. Confirm the PRD, and the machine
takes it from there.

## Evaluate — `/evaluate-pr` and `/evaluate-sessions`

The back bookend, and the mirror of `/intent`. The harness hands you a finished
PR; evaluation is where you do the unverifiable work the machine couldn't. There
are two skills, because there are two things to evaluate.

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
never hand work back to the loop. You are the last mile.

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
  reference file, the `AGENTS.md` pointer, or the skill.

This is the moment the framing of the whole book becomes literal: every PR the
harness builds is a graded trial of your project's context, and every eval you
capture makes the project a little better at building itself next time. You're
not auditing one PR — you're **tuning the harness.**

## Memory still has one write path

Notice what evaluation does *not* do: it doesn't write memory directly. Whatever
you learn here isn't ground truth yet, because the change isn't merged yet. So
the insight either becomes a pushed fix that rides into `main` — where `/learn`
(Chapter 4) picks it up as ground truth to extend, not second-guess — or it lives
in your head and sharpens the next Intent. Evals and context fixes land on a
branch and reach memory the same way: through a merge. The single write path of
Chapter 4 holds. You may now *seed* memory deliberately; you still never bypass
the door.

## The three places you steer

Across the whole system, you touch the machine at exactly three points — and
every one of them is a phase of this loop:

| You... | Human-loop phase | What it does to the machine |
|---|---|---|
| Confirm a PRD | end of **Intent** | starts the build |
| Evaluate and merge a PR | **Evaluate** | ends the build; triggers `/learn` |
| Unstick a STUCK feature | a forced detour into **Evaluate** | corrects the context, then merges |

Three touchpoints. Everything between them is the machine. Everything *at* them
is judgment — yours.

---

So here's where we've arrived. The project plans, implements, verifies, and
remembers on its own. You spend your time understanding the problem, expressing
intent, and evaluating outcomes — and when you evaluate, you don't just approve
work, you improve the thing that produced it.

That's not a new workflow bolted onto coding. It's a different relationship to
your own project. Worth saying plainly, because it's the whole point.

→ [Chapter 6 — The mindset shift](./6-the-mindset-shift.md)
