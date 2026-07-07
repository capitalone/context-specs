# Unstick a feature

When a feature cannot get through a step honestly, the harness declares it
**STUCK**, posts a diagnostic to the PR, and halts that feature. STUCK is a
*finished* state, not a crash — the system told you the truth instead of faking
success. Unsticking it is a forced detour into the [Evaluate phase](../concepts/the-human-loop.md),
and it is one of the three places you steer the machine.

## What the harness hands you

A STUCK PR comes with everything needed to diagnose it:

- The **step that capped** and its retry budget.
- A **session log** of every `claude -p` invocation across the chain — open any
  trace and see exactly what the agent saw.
- A **tail of the failing output**.
- One instruction: run **`/improve-context <PR#>`**.

## Steps

You don't need to hold the forensics machinery in your head — the skill does:

```bash
cd ~/code/myapp
claude
> /improve-context <PR# or feature>
```

1. It resolves the session IDs to local traces and reads the trail *with* you,
   tracing the cause upstream of the symptom.
2. Together you **identify which piece of context misled the agent** — a stale
   Expert note, a thin spec, a PRD gap, an environment the agent couldn't
   navigate — and **fix that context first, on the PR's branch**. This is the
   [context-gap fix](../concepts/continuous-improvement.md#two-ways-to-fix-a-problem-very-different-leverage)
   that stops the *class* of failure, not just this instance. (Sometimes the
   task was just hard and no context change would have helped — naming that is
   a valid outcome too.)
3. **Then it fixes the code** until `run-prd-test.sh` passes honestly — never by
   silencing a check — and offers to freeze the learning as an
   [eval](./improve-context.md).
4. **You merge.**

## Why the order matters

If the context that caused the failure stays wrong, the same class of failure comes
back the next time a feature touches that area. Fixing the code fixes one feature;
fixing the context fixes the class.

Because you correct the context *on the feature branch* and merge it, that
correction is in the diff [`/learn`](../concepts/long-term-memory.md) reads — so your
hand fix becomes permanent project memory automatically. Every STUCK you resolve
this way raises the [ready-to-merge ratio](../concepts/continuous-improvement.md#the-metric-the-ready-to-merge-ratio).

## Related

- [Improve your project's context](./improve-context.md) — the skill this flow
  runs through, and everything else it can do.
- [The output contract](../concepts/output-contract.md) — what STUCK means and why
  the harness refuses to fake success.
- [Continuous improvement](../concepts/continuous-improvement.md) — why the
  context-first order compounds.
