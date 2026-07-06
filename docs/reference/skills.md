# Reference: the pieces

Context Specs is a deterministic CLI and dispatcher plus a set of Agent Skills. This
is the catalog. The CLI and dispatchers are the harness's deterministic half; the
skills are its probabilistic half.

## Deterministic half

| Where | Piece | Does |
|---|---|---|
| **CLI** (`bin/context-specs`) | `init` / `add` / `link` / `remove` | Create the harness repo; register environments; symlink skills |
| | `start` / `stop` / `run` | Supervise the loops (drain-on-advance) / one foreground pass |
| | `status` / `logs` / `doctor` | Observe every environment; check the wiring |
| **Dispatchers** (`scripts/`) | `poll-and-dispatch.sh` | The build loop: PRD → PR, one deterministic step per tick |
| | `learn-dispatch.sh` | The memory loop: merged diff → `learn/<sha>` PR |

See [Reference: the CLI](./cli.md) for full command detail.

## Probabilistic half — Agent Skills

### SDD skills (`skills/sdd/`) — short-term memory

| Skill | Does |
|---|---|
| [`/spec-planning`](../../skills/sdd/spec-planning/SKILL.md) | PRD → mainspec + temporal slices |
| [`/spec-validate`](../../skills/sdd/spec-validate/SKILL.md) | Multi-agent consensus review of the plan |
| [`/implement-mainspec`](../../skills/sdd/implement-mainspec/SKILL.md) | Orchestrate slices in dependency order |
| [`/implement-slice`](../../skills/sdd/implement-slice/SKILL.md) | Implement one slice: write, unit-test, Reflect |

See [Spec-Driven Development](../concepts/spec-driven-development.md).

### Harness skills (`skills/harness/`)

| Skill | Does |
|---|---|
| [`/env-init`](../../skills/harness/env-init/SKILL.md) | Guided setup of a project as an environment (the Software 3.0 half) |
| [`/fix-local-checks`](../../skills/harness/fix-local-checks/SKILL.md) | Honest fixes for a failing pre-PR gate |
| [`/address-feedback`](../../skills/harness/address-feedback/SKILL.md) | Triage and answer reviewer findings |
| [`/learn`](../../skills/harness/learn/SKILL.md) | Post-merge long-term memory update |

See [Long-term memory](../concepts/long-term-memory.md).

### Human-loop skills (`skills/human-loop/`)

| Skill | Does |
|---|---|
| [`/wiki-init`](../../skills/human-loop/wiki-init/SKILL.md) | Stand up a Karpathy LLM-wiki (Understanding) |
| [`/intent`](../../skills/human-loop/intent/SKILL.md) | Idea → PRD + runnable definition of done (project-owned) |
| [`/evaluate-pr`](../../skills/human-loop/evaluate-pr/SKILL.md) | Evaluate the change; build understanding |
| [`/evaluate-sessions`](../../skills/human-loop/evaluate-sessions/SKILL.md) | Evaluate the build trail; capture evals |

See [The human loop](../concepts/the-human-loop.md).

## Project-owned vs. harness-owned

Most skills are symlinked from the harness repo into each environment (gitignored).
Two are deliberately project-owned — committed to the environment and tuned per
project: **`/intent`** and the **Expert**. See
[the two-tier architecture](../concepts/two-tier-architecture.md#the-two-developer-owned-levers).
