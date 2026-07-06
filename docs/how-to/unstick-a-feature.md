# Unstick a feature

When a feature cannot get through a step honestly, the harness declares it
**STUCK**, posts a diagnostic to the PR, and halts that feature. STUCK is a
*finished* state, not a crash — the system told you the truth instead of faking
success. Unsticking it is a forced detour into the [Evaluate phase](../concepts/the-human-loop.md),
and it is one of the three places you steer the machine.

## What the harness hands you

A STUCK PR comes with everything you need to diagnose it:

- A **session log** of every `claude -p` invocation across the chain — open any
  trace and see exactly what the agent saw.
- A **tail of the failing output**.
- A **diagnosis-first checklist**.

## Steps

Work the checklist in order — and note that its first item is *not* "fix the code":

1. **Identify which piece of context misled the agent.** A stale Expert note, a
   thin spec, a PRD that left something out, an environment the agent could not
   navigate. Read the trace to find where it went wrong.
2. **Fix that context first.** Correct the Expert reference, sharpen the
   definition of done, add the missing detail. This is the
   [context-gap fix](../concepts/continuous-improvement.md#two-ways-to-fix-a-problem-very-different-leverage)
   that stops the *class* of failure, not just this instance.
3. **Then make the feature pass** on its branch, honestly — never by silencing a
   check.
4. **Merge.**

## Why the order matters

If the context that caused the failure stays wrong, the same class of failure comes
back the next time a feature touches that area. Fixing the code fixes one feature;
fixing the context fixes the class.

Because you correct the context *on the feature branch* and merge it, that
correction is in the diff [`/learn`](../concepts/long-term-memory.md) reads — so your
hand fix becomes permanent project memory automatically. Every STUCK you resolve
this way raises the [ready-to-merge ratio](../concepts/continuous-improvement.md#the-metric-the-ready-to-merge-ratio).

## Related

- [The output contract](../concepts/output-contract.md) — what STUCK means and why
  the harness refuses to fake success.
- [Continuous improvement](../concepts/continuous-improvement.md) — why the
  context-first order compounds.
