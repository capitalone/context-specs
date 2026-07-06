# The human loop

Once the machine does the typing, what is left is the part only you can do — and it
is the most important part, not the leftover. The human loop is you, deliberately
working the judgment a harness structurally cannot supply.

## Outsource your thinking, not your understanding

The governing line comes from Andrej Karpathy: *"you can outsource your thinking but
you can't outsource your understanding."* It draws a sharp boundary:

- **Verifiable work → outsource it freely.** Syntax, API recall, implementation
  mechanics. The model is superhuman here; spending your attention on it is waste.
- **Unverifiable work → you must own it.** Whether this is the right thing to
  build, whether the abstraction is sound, whether the edge cases are handled for
  good reasons, whether the UX feels right. Errors here are subtle and do not
  announce themselves — exactly where your understanding has to be load-bearing.

The harness took the first category. The human loop is you, deliberately working
the second.

## Three phases, one cycle

```
   Understanding ──▶ Intent ──▶ [ the harness builds ] ──▶ Evaluate
   build your model    express        the machine loop       walk the result,
   of the problem      what to                               run it, judge it,
   space               build                                improve the context
        ▲                                                        │
        └──────────── evaluating deepens understanding ──────────┘
```

The human loop and the machine loop are not parallel tracks — they feed each other:

> **Your loop's output is the harness's input. The harness's output is your loop's
> input.**

You produce intent (a PRD); the harness consumes it and produces a pull request;
you consume that PR by evaluating it; what you learn sharpens the next intent.
Naming your loop explicitly is what keeps *your* job legible as the machine takes
over more of the typing.

## Understanding — `/wiki-init`

Before you can express good intent, you need a real model of the problem space: the
domain, the prior art, the constraints, the trade-offs.
[`/wiki-init`](../../skills/human-loop/wiki-init/SKILL.md) stands up a standalone,
LLM-maintained knowledge base in the shape of Karpathy's "LLM Wiki": you synthesize
**once, at ingest time**, into durable, cross-linked pages that compound as sources
accumulate. You curate sources and ask questions; the LLM does the bookkeeping
humans abandon wikis over.

This wiki is deliberately **not** a project artifact — hold this bright line:

- The **wiki** is cross-project **domain and architecture** knowledge, written to
  be read **by you**. It lives in its own repo, outside any codebase.
- The **Expert** ([long-term memory](./long-term-memory.md)) is per-project **code**
  memory, written to be read **by agents**.

A richer model of the domain means a sharper `/intent`.

## Intent — `/intent`

[`/intent`](../../skills/human-loop/intent/SKILL.md) is where understanding becomes
a buildable thing. Its discipline:

- **Elicit outcomes, not solutions.** People arrive describing a solution ("add a
  `/api/search` endpoint"); the job is to surface the *need* underneath ("readers
  can't find a post by title") and the observable outcome that would satisfy it.
- **"How would we know that's true?"** is the throughline. Asked of every desired
  outcome, it converts a wish into both a sharp prose criterion *and* a concrete
  check — the coupled `prd.md` + `run-prd-test.sh` born together (see the
  [output contract](./output-contract.md)).
- **You don't write the runner; the Expert drafts it, you review.** This keeps
  verification grounded in how the project actually works.

`/intent` is a coordinator, not a knowledge holder — the domain reasoning comes from
the Expert; your contribution is understanding and the judgment about what is worth
building. See [Express intent](../how-to/express-intent.md).

## Evaluate — `/evaluate-pr` and `/evaluate-sessions`

The back bookend, and the mirror of `/intent`. There are two skills, because there
are two things to evaluate.

- **[`/evaluate-pr`](../how-to/evaluate-a-pr.md)** — evaluate *what was built*. The
  tangible output is merge, fix-and-push, or close; the output that matters more is
  *you* understanding the change deeply enough to defend every decision in it. The
  bot reviewer already caught the mechanical defects, so this skill sets those aside
  and spends your attention on what a bot cannot judge — is this simpler than it
  could be, is the abstraction sound, does the UX feel right? If the walk surfaces
  something to change, **you fix it here and push** — you never hand work back to
  the loop. You are the last mile.
- **[`/evaluate-sessions`](../how-to/improve-from-traces.md)** — evaluate *how it
  was built*. This is where the human loop reaches back and improves the harness
  itself, reading the `claude -p` build trail to find where context served the
  agents or failed them, and freezing what you find as evals and context fixes. This
  is the heart of [continuous improvement](./continuous-improvement.md).

## Memory still has one write path

Evaluation does *not* write memory directly. Whatever you learn here is not ground
truth yet, because the change is not merged yet. So the insight either becomes a
pushed fix that rides into `main` — where `/learn` picks it up — or it lives in your
head and sharpens the next Intent. Evals and context fixes land on a branch and
reach memory the same way: through a merge. You may now *seed* memory deliberately;
you still never bypass the door. See [long-term memory](./long-term-memory.md#one-write-path-ground-truth-only).

## The three places you steer

Across the whole system you touch the machine at exactly three points — and every
one is a phase of this loop:

| You... | Human-loop phase | What it does to the machine |
|---|---|---|
| Confirm a PRD | end of **Intent** | starts the build |
| Evaluate and merge a PR | **Evaluate** | ends the build; triggers `/learn` |
| Unstick a STUCK feature | a forced detour into **Evaluate** | corrects the context, then merges |

Three touchpoints. Everything between them is the machine. Everything *at* them is
judgment — yours.

## Related

- [Continuous improvement](./continuous-improvement.md) — evaluation is how you
  drive the flywheel.
- [Harness engineering](./harness-engineering.md) — what the machine half
  guarantees, so you can spend your attention here.
