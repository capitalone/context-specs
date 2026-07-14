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

## The two eval families

What you learn can be frozen as runnable evals, committed to your project under
`evals/` and run right where you are — no worktrees, no harness machinery:

- **`evals/long-term-memory/`** — does the Expert actually improve spec plans? Real
  PRDs from shipped features become fixtures; `/spec-planning` runs with and without
  the Expert; an LLM judge compares the plans blind against a **human-approved gold**.
  The judge also reports what the Expert *should* have contained — each run is a grade
  and an improvement backlog.
- **`evals/lints/`** — is each lint's failure message a sufficient prompt? A mocked
  violation, the message alone, a cold `claude -p`, a judge.

Each eval prints a **report** — to your terminal and to `<case>/.cache/last-report.md`, so
the skill reads it with you and helps you decide the next move (keep the edit, refine it, or
revert). Its **verdict must move** when the context under test moves — worse against the
defect, better after the fix — the same right-reason discipline as the PRD runner, but the
signal is the report's verdict, not a pass/fail exit code.

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
