# The output contract: ready-to-merge or STUCK

The harness makes one promise: for every feature you start, you get back a pull
request in one of exactly two finished states — **ready to merge** or **STUCK with
a diagnosis**. This page covers how "done" is defined, how it is proven, and what
each terminal state means. It is the mechanics behind the guarantee introduced in
[harness engineering](./harness-engineering.md).

## The definition of done is runnable

The input to the harness is not just a prose description; it is a PRD paired with an
**executable definition of done**. `/intent` produces two coupled artifacts:

- `prds/<feature>/prd.md` — the prose: **why** this exists and **what** "done"
  means;
- `prds/<feature>/run-prd-test.sh` — the executable: **how you will know** it is
  done. It exits 0 when the feature is built.

The runner is the load-bearing idea, and it is what makes the harness
**goal-based**: the runner *is* the goal, and the loop keeps invoking the model
until the goal is met or the retry caps call it honestly unreachable. Prose drifts
and "done" becomes an argument; an exit code does not.

Before `/intent` commits anything, it runs the script against today's unbuilt code
and confirms it fails **for the right reason** — because the behavior is genuinely
absent, not because of a typo or a missing dependency. That is the empirical proof
that the test actually corresponds to the intent. See
[Express intent](../how-to/express-intent.md) for how to write one.

## Verification the agent cannot talk past

Autonomy is only safe if "done" cannot be faked, so the harness leans on checks
that run **regardless of what the agent decides**, fastest to slowest:

1. **Pre-commit hooks** — linters, formatters, type checks on changed files.
2. **Slice unit tests** — each slice's tests, run during implementation.
3. **`local-checks.sh`** — the cheapest gate before a PR: lint, typecheck, the fast
   unit suite, skip-detection, and any custom project lints. It proves
   **correctness, not coverage** — it blocks on real defects and merely warns on
   style.
4. **The PRD runner** — `./prds/<feature>/run-prd-test.sh` must exit 0. This is the
   definition of done, and because it can mix deterministic shell checks with an
   LLM-as-judge, "runnable" does not force everything into unit-test shape.

The agent does not get to decide whether these run — they run, and the git/CI layer
enforces them independently. Crucially, **silencing a check counts as bypassing
it**: an agent may never add a suppression directive, weaken a config, or skip a
test to reach green. A check it cannot pass honestly is one it lets fail.

## Ready to merge

The first terminal state: the feature is built, every check passed, the PR is open
and the reviewer has no findings left. What is waiting for you is finished work you
never typed — ready for your judgment, not your typing. Evaluating it is the
[human loop](./the-human-loop.md)'s job, not the harness's.

## STUCK

Sometimes a feature genuinely cannot get through a step — a plan is subtly wrong, a
check will not pass honestly. The harness does not loop forever and will not fake
success. Every step has a bounded retry budget; when a step hits its cap, the
dispatcher declares the feature **STUCK**, posts a diagnostic to the PR, and halts
that feature until you step in.

What it hands you is deliberate. Not just "it failed" — a session log of every
`claude -p` invocation across the chain (so you can open any trace and see what the
agent saw), a tail of the failing output, and a pointer to
**[`/improve-context`](../how-to/improve-context.md)**, which walks the
diagnosis-first flow with you. The first move is not "fix the code." It is
*identify which piece of context misled the agent* — a stale Expert note, a thin
spec, a PRD that left something out — and correct that first. Because if the
context that caused the failure stays wrong, the same class of failure comes back
the next time a feature touches that area. See
[Unstick a feature](../how-to/unstick-a-feature.md).

## Both states are finished — and the ratio is your metric

Ready-to-merge and STUCK are **both finished states**: the system completed its run
and told you the truth about which one you got. It never returns "maybe."

The ratio between them is the number to watch. Every STUCK names a piece of context
to improve, and every improvement raises the odds the next feature comes back
ready. Driving that ratio up over time is [continuous improvement](./continuous-improvement.md)
— the reason the harness is worth tuning rather than just running.

## Related

- [Harness engineering](./harness-engineering.md) — where the guarantee comes from.
- [The dispatcher](./the-dispatcher.md) — the engine that drives every feature to
  one of these two states.
- [Design invariants](../reference/invariants.md) — the proof the verification
  layers cannot be talked past.
