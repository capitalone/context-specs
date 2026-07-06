# Evaluate a PR

When the harness hands back a **ready-to-merge** PR, evaluating it is your job — the
[unverifiable work](../concepts/the-human-loop.md#outsource-your-thinking-not-your-understanding)
the machine could not do. `/evaluate-pr` is a teacher and a taste partner, not a
second linter.

## Prerequisites

- A ready PR from the harness.
- You are running `claude` inside the project.

## Steps

```bash
cd ~/code/myapp
claude
> /evaluate-pr
```

[`/evaluate-pr`](../../skills/human-loop/evaluate-pr/SKILL.md) produces two outcomes:

- **The tangible one:** merge, fix-and-push, or close.
- **The one that matters more:** *you* understanding the change deeply enough to
  defend every scenario and design decision in it.

Because the bot reviewer already caught the mechanical defects, the skill *ingests*
those findings and sets them aside, then spends your attention on what a bot
structurally cannot judge:

- Is this simpler than it could be?
- Is the abstraction sound?
- Does the UX feel right?

It runs the system with you, walks the definition-of-done scenarios live, and probes
Socratically rather than lecturing. The understanding gate is soft but real: it ends
on "do you feel you understand this change?" and skipping the walk-through is an
explicit opt-out, never a silent rubber-stamp.

## If you find something to change

**Fix it here and push.** You never hand work back to the loop — you are the last
mile. Whatever you fix rides into `main` on the merge, where
[`/learn`](../concepts/long-term-memory.md) picks it up as ground truth.

## Why this closes the loop

The understanding you build here is the literal mechanism that sharpens your next
[intent](./express-intent.md) — evaluating deepens understanding, which produces
better intent, which the harness builds. When you evaluate, you do not just approve
work; you improve the thing that produced it.

## Related

- [Improve from build traces](./improve-from-traces.md) — evaluate *how* it was
  built, not just what.
- [The human loop](../concepts/the-human-loop.md) — where this phase sits.
