# Improve your project's context

`/improve-context` is the harness concierge — the skill that knows the whole context
system so you don't have to. One front door for resolving STUCKs, improving any context
lever, and building evals over the harness itself. This is the engine of
[continuous improvement](../concepts/continuous-improvement.md).

## Prerequisites

- You are running `claude` inside the project.
- For STUCK work: the PR the harness opened (its build trail is posted on the PR).

## Three ways in

```bash
cd ~/code/myapp
claude
> /improve-context                      # no args: survey and propose a focus
> /improve-context 42                   # a STUCK (or any) PR: diagnosis-first forensics
> /improve-context improve long-term memory with our new auth direction
```

[`/improve-context`](../../skills/human-loop/improve-context/SKILL.md) routes all three
across the same **lever map**:

- **The Expert** (long-term memory) — the biggest lever; informs every spec plan. Facts
  *and* direction belong here; update it rapidly and constantly.
- **`AGENTS.md`** — eager memory; every line is a standing tax, so it points into the
  Expert rather than duplicating it.
- **`/intent`** — the input lever: PRD elicitation quality and, above all, the
  `run-prd-test.sh` verification strategy, which evolves per work type over time.
- **Lints** (`scripts/local-checks.sh` + `scripts/lints/`) — deterministic memory an
  agent cannot ship past; the failure message doubles as the fix-prompt.
- **Evals** (`evals/`) — the lever that measures the levers.

## Resolving a STUCK

The STUCK PR hands you the step that capped, a session table, and a failing-output
tail — plus one instruction: run `/improve-context <PR#>`. The skill resolves the
sessions to local traces, reads the trail *with* you (tracing the cause upstream of the
symptom), and walks the diagnosis-first order: fix the context that misled the agent on
the branch, then the code, then merge — the merge carries both, and `/learn` makes the
context fix permanent. See [Unstick a feature](./unstick-a-feature.md).

## Evals — freezing what you learn

What you learn can be frozen as runnable evals, committed to your project under `evals/`
and run right where you are. Their folder tree mirrors your project's own context levers,
and every case is graded against a **rubric of your intent** — how the system should
behave, its conventions, its direction — never against the shipped code (that would be
circular: the lesson you just added is already in the code). The rule that keeps it honest:
a criterion rewards a shard's **effect**, not its **echo** — it tests the outcome the shard
produces, not whether a plan quotes it.

Evals come in two kinds:

- **Single-lever checks (Tier 1) — cheap, many.** Each tests **one** context lever on its
  own. `evals/expert/` and `evals/agents-md/` ask "did this shard/line change the plan, for
  the better?" by answering the same targeted planning question **twice — once with the
  context, once without — then comparing** (so the verdict moves with the context by
  construction). `evals/intent/` gates whether a PRD + runner is a sufficient, right-reason
  spec; `evals/lints/` asks whether a lint's failure message works as a fix-prompt read
  cold.
- **Whole-plan checks (Tier 2) — expensive, few.** Re-plan an entire feature at HEAD — once
  with the shard, once without — and judge the whole plan. This is the real `/spec-planning`
  invocation, where all your levers converge. Kept small (3–5, spanning work types); the
  disposable re-plan is the only worktree involved, torn down after.

**Where to start.** Fill in single-lever checks before reaching for whole-plan ones — the
skill suggests this, and you can override it. The highest-leverage place to begin is a shard
in the Expert (`evals/expert/`), because long-term memory feeds the spec plan, which shapes
**every future feature**: a fix there tunes the input to every plan the harness will ever
write. You're working at the level of the whole system, not one feature.

Each eval prints a **report** — to your terminal and to `<case>/.cache/last-report.md`, so
the skill reads it with you and helps you decide the next move (keep the edit, refine it, or
revert). Its **verdict must move** when the context under test moves — the same right-reason
discipline as the PRD runner, but the signal is the report's verdict (`HELPED | NEUTRAL |
HURT`, or `PASS | FAIL`), not a pass/fail exit code.

## How it reaches memory

Context fixes and evals land on a branch — the STUCK PR's own branch, or a small
`capture/<slug>` PR — so every change stays reviewable and revertible. On merge,
[`/learn`](../concepts/long-term-memory.md) treats your memory edits as authoritative
and extends them. And the Expert is yours to edit directly any time: memory holds
current facts *and* decisions or direction the code hasn't caught up to.

## Why it matters

Every PR the harness builds is a graded trial of your project's context. You are not
auditing one PR — you are **tuning the harness**, and every context fix and eval makes
the project a little better at building itself next time. That is what drives the
[ready-to-merge ratio](../concepts/continuous-improvement.md#the-metric-the-ready-to-merge-ratio)
up over time.

## Related

- [Continuous improvement](../concepts/continuous-improvement.md) — the flywheel this
  feeds.
- [Unstick a feature](./unstick-a-feature.md) — the STUCK entry point in detail.
- [Evaluate a PR](./evaluate-a-pr.md) — the companion skill: evaluate *what* was built.
