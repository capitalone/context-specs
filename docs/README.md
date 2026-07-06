# Context Specs documentation

Context Specs is [harness engineering](./concepts/harness-engineering.md) applied to
building software: you express intent, and a deterministic harness drives a coding
model all the way to a pull request that is either **ready to merge** or **STUCK
with a diagnosis**. Over time you improve the *system* — its context, its memory,
its checks — so more features come back ready and fewer come back stuck.

New here? The top-level [README](../README.md) is the elevator pitch. For the full
narrative, read the [overview](./overview.md). Otherwise, jump straight to a concept
or a task below.

## Overview

- **[How Context Specs works](./overview.md)** — the narrative tour that connects
  every concept in one reading.

## Core concepts

Standalone explanations of each idea. Read in any order; they cross-link.

- **[Harness engineering](./concepts/harness-engineering.md)** — what a harness is
  (Agent = Model + Harness), and the discipline the whole system rests on.
- **[Context engineering](./concepts/context-engineering.md)** — the core lever:
  the right context in the window at the right time.
- **[The two-tier architecture](./concepts/two-tier-architecture.md)** — one harness
  repo driving N environments; the Software 3.0 dividing line.
- **[The dispatcher](./concepts/the-dispatcher.md)** — the deterministic engine;
  artifacts as state; a fresh window per step.
- **[Spec-Driven Development](./concepts/spec-driven-development.md)** — short-term
  memory: context engineering for one feature.
- **[Long-term memory](./concepts/long-term-memory.md)** — the Expert, `AGENTS.md`,
  and lints; how the harness remembers.
- **[The output contract](./concepts/output-contract.md)** — the runnable definition
  of done; ready-to-merge vs. STUCK.
- **[Continuous improvement](./concepts/continuous-improvement.md)** — operating at
  the system level; the ready-to-merge ratio; the flywheel.
- **[The human loop](./concepts/the-human-loop.md)** — understand → intent →
  evaluate; the part only you can do.

## How-to guides

Task-oriented steps for getting things done.

- **[Create a harness](./how-to/create-a-harness.md)** — `init` your one harness
  repo.
- **[Add an environment](./how-to/add-an-environment.md)** — register a project.
- **[Initialize a project](./how-to/initialize-a-project.md)** — generate the
  Software 3.0 half with `/env-init`.
- **[Express intent](./how-to/express-intent.md)** — turn an idea into a PRD +
  runnable definition of done.
- **[Run the harness](./how-to/run-the-harness.md)** — start, observe, and stop the
  loops.
- **[Unstick a feature](./how-to/unstick-a-feature.md)** — resolve a STUCK by fixing
  the context first.
- **[Evaluate a PR](./how-to/evaluate-a-pr.md)** — evaluate *what* was built.
- **[Improve from build traces](./how-to/improve-from-traces.md)** — evaluate *how*
  it was built; capture evals and context fixes.

## Reference

- **[The `context-specs` CLI](./reference/cli.md)** — every command, flag, and exit
  code.
- **[The pieces](./reference/skills.md)** — the full catalog of CLI commands,
  dispatchers, and skills.
- **[State and branches](./reference/state-and-branches.md)** — the branch namespace
  and on-disk layout.
- **[Design invariants](./reference/invariants.md)** — the properties that make the
  harness safe to leave running.
