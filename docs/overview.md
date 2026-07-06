# How Context Specs works

This is the narrative tour — the through-line that connects the
[core concepts](./README.md#core-concepts) in one reading. If you prefer to jump
straight to a concept or a task, use the [documentation map](./README.md). If you
want the whole idea in one sitting, read on.

## The one idea

Context Specs is [harness engineering](./concepts/harness-engineering.md) applied to
building software. An **agent is a model plus a harness** — the model supplies
probabilistic intelligence, the harness supplies deterministic control. Harness
engineering is building a system with defined inputs and defined outputs, where the
deterministic code invokes the probabilistic code and drives the flow all the way to
a guaranteed output.

Here the input is a PRD with a runnable definition of done. The output is **a pull
request that is either ready to merge or STUCK with a diagnosis** — never a guess.
That output is also the system's feedback signal, and improving the ratio between
the two is the whole game.

## The lever underneath everything

Every part of the system is an application of one lever:
[context engineering](./concepts/context-engineering.md) — controlling what enters an
agent's context window, and what stays out. The window is finite and it degrades
(decay, pollution, compaction), so the discipline is to externalize durable
knowledge to the filesystem and let the agent pull just what it needs, just in time.
Watch that same lever get pulled at larger and larger scope as the story goes on.

## Building one feature: short-term memory

The smallest unit of work is a feature.
[Spec-Driven Development](./concepts/spec-driven-development.md) is context
engineering applied to one feature: think outside the window first, and persist the
plan as a **mainspec** plus ordered **slices** on disk. The agent is fed one slice
at a time, so its window stays small and the plan can't decay or compact away. A
spec is the harness's **short-term memory** — a point-in-time plan for one feature,
disposable once the feature ships. It is *not* where durable knowledge lives.

## Running it unattended: the machine

[The dispatcher](./concepts/the-dispatcher.md) takes that feature loop and runs it
autonomously. It can be trusted unattended because it keeps **no hidden state**:
every feature's state is observable from files on disk and branches in git. A small
deterministic bash script reads that state each tick and shells out to a fresh
`claude -p` process per step — so no step inherits another's polluted window, crash
recovery is free, and there is **no LLM in the decision path**. It never touches your
checkout; it works your repo's refs and its own sibling worktrees.

What makes "done" trustworthy is [the output contract](./concepts/output-contract.md):
a runnable definition of done the agent cannot argue with, backed by verification
layers it cannot talk past. When a feature can't finish honestly, the harness stops
and hands you a diagnosis — **STUCK** — instead of faking success. This all runs
across [one harness driving N environments](./concepts/two-tier-architecture.md),
split cleanly between the project-agnostic harness repo and the Software 3.0 pieces
generated per project.

## Getting better every merge: the flywheel

A harness that only built features would relearn the same lessons forever. This one
remembers. [Long-term memory](./concepts/long-term-memory.md) — the Expert (lazy,
pulled on demand), `AGENTS.md` (eager, a map into the Expert), and lints (the memory
an agent cannot ship past) — is updated on every merge through a single, auditable
write path.

That is the start of [continuous improvement](./concepts/continuous-improvement.md),
the idea at the center of the whole system: **you operate on the system that
produces features, not on the features themselves.** Fix a piece of code and you
ship one feature. Fix a context gap and every future feature benefits. You do both,
but context-gap fixes are the main thing, because they compound — and the
ready-to-merge ratio is the metric you drive up.

## Your job: the human loop

Strip away the typing and what is left is not less work — it is higher-leverage
work. [The human loop](./concepts/the-human-loop.md) is the part a harness cannot
do: **understand** the problem (`/wiki-init`), express **intent** with a real
definition of done (`/intent`), and **evaluate** what comes back (`/evaluate-pr`,
`/evaluate-sessions`). When you evaluate, you don't just approve work — you improve
the thing that produced it.

Put it together and your project stops being a codebase you type into and becomes a
harness you tune. A codebase you type into is a constant cost. A harness you tune is
an appreciating asset — each feature leaves it a little more capable of building the
next one.

## Keep reading

- Jump into any [core concept](./README.md#core-concepts).
- Follow a [how-to guide](./README.md#how-to-guides) to do something specific.
- Read the [design invariants](./reference/invariants.md) for the proof the machine
  is safe to leave running.
