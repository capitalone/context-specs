# Improve the harness from build traces

`/evaluate-sessions` is where you evaluate *how* a feature was built, not just what
was built — and turn what you find into durable improvements to the harness itself.
This is the engine of [continuous improvement](../concepts/continuous-improvement.md).

## Prerequisites

- A PR the harness built (its `claude -p` build trail is posted on the PR).
- You are running `claude` inside the project.

## Steps

```bash
cd ~/code/myapp
claude
> /evaluate-sessions
```

[`/evaluate-sessions`](../../skills/human-loop/evaluate-sessions/SKILL.md) reads the
build trail *with you* to find where the project's context served the agents and
where it failed them — where an agent re-derived something the Expert should have
told it, followed a stale `AGENTS.md` pointer, or guessed because a spec was thin.

## The two durable outcomes

What you find turns into two things, both of which persist:

- **Evals** — when a session shows a skill behaved well or badly *given the context
  it had*, freeze that as a runnable check under `evals/`. An eval is a regression
  test over the harness's **own skills and context** (the analog of testing a
  prompt), distinct from the PRD runner, which tests the product.
- **Context fixes** — when a piece of context misled an agent, fix the Expert
  reference, the `AGENTS.md` pointer, or the skill.

The shape is always the same:

> *Observe a trace → capture it as an eval → fix the context → it persists as a
> regression test.*

## How it reaches memory

Evals and context fixes are not ground truth until merged, so they land on a branch
and reach memory the same way everything else does — through a merge, where
[`/learn`](../concepts/long-term-memory.md#one-write-path-ground-truth-only) picks
them up. You may *seed* memory deliberately here; you still never bypass the single
write path.

## Why it matters

Every PR the harness builds is a graded trial of your project's context. You are not
auditing one PR — you are **tuning the harness**, and every eval you capture makes
the project a little better at building itself next time. That is what drives the
[ready-to-merge ratio](../concepts/continuous-improvement.md#the-metric-the-ready-to-merge-ratio)
up over time.

## Related

- [Continuous improvement](../concepts/continuous-improvement.md) — the flywheel
  this feeds.
- [Evaluate a PR](./evaluate-a-pr.md) — the companion skill: evaluate *what* was
  built.
