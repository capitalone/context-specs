# Continuous improvement: operating at the system level

This is the idea at the center of Context Specs: **you work on the system that
produces features, not on the features themselves.** A harness that only built
features would be a fast worker with no memory. This one gets measurably better at
building *your* project every time it builds — and it improves in a direction you
choose.

## Two ways to fix a problem, very different leverage

When a feature comes out wrong, you can fix it at two levels, and the difference is
the whole point:

- **Fix the code.** You correct this one feature and ship it. Nothing else changes.
  The next feature starts from the same place the last one did. This is real work,
  and sometimes it is all a situation needs — but its leverage is exactly one
  feature.
- **Fix the context gap.** You find *why* the agent got it wrong — a thin
  definition of done, a missing piece of [long-term memory](./long-term-memory.md),
  an environment the agent could not navigate, a rule nobody wrote down — and you
  correct *that*. Now every future feature that touches the same area benefits. You
  fixed a *class* of failure, not an instance.

You do both. But **context-gap fixes are the main thing**, because they compound
and code fixes do not. Fixing the code fixes one feature; fixing the context fixes
the class.

## The metric: the ready-to-merge ratio

The harness's [output contract](./output-contract.md) gives you a clean signal to
optimize. Every feature ends **ready-to-merge** or **STUCK**, and the ratio between
them is your metric. It is not a vanity number — it is directly actionable, because
every STUCK *names the context to improve*. The job of continuous improvement is to
drive that ratio up: fewer stuck features, more that come back ready, as the
project's context gets sharper.

A codebase you type into is a constant cost — it decays, it needs maintenance,
every feature starts roughly where the last one did. A harness you tune is an
**appreciating asset** — each feature leaves the project a little more capable of
building the next one.

## The flywheel has several engines

Improvement enters the system through more than one path, and they reinforce each
other:

- **`/learn` (the machine loop).** After every merge, the harness reads the merged
  diff and updates [long-term memory](./long-term-memory.md) — routing durable
  lessons into the Expert, `AGENTS.md`, or a lint. Automatic, behind a human merge.
- **Lints (the memory an agent cannot ship past).** The highest-leverage
  improvement: a recurring lesson promoted to a short script whose error message is
  itself a fix prompt. Once written, it protects every future PR. See
  [long-term memory](./long-term-memory.md#lints-the-memory-an-agent-cannot-ship-past).
- **Evals (the human loop).** Reading the build trail with
  [`/evaluate-sessions`](../how-to/improve-from-traces.md) surfaces where the
  project's context served or failed the agents. What you find is frozen as a
  runnable eval — a regression test over the harness's *own skills and context* —
  and captured as a context fix.
- **Unsticking (the forced detour).** Every STUCK you resolve by correcting the
  misleading context, then merging, feeds that correction into `/learn` as ground
  truth. See [Unstick a feature](../how-to/unstick-a-feature.md).

The common shape across all four:

> *Observe a trace → capture it as an eval or a lint → fix the context → it
> persists.*

## Why this is the job now

Strip away the typing — the part a model does better than you — and what is left is
not "less work." It is *higher-leverage* work: shaping the context the harness
reasons over, deciding what becomes a lint versus flexible prose, and reading the
build trail to fix what failed an agent. Fixing the code fixes one feature. Fixing
the context fixes the class. That shift, from operating on features to operating on
the system, is what lets one engineer do far more — and it is the whole bet of
Context Specs.

## Related

- [Long-term memory](./long-term-memory.md) — the durable store the flywheel writes
  to.
- [The human loop](./the-human-loop.md) — the phases where *you* drive improvement.
- [The output contract](./output-contract.md) — where the ready-to-merge/STUCK
  signal comes from.
