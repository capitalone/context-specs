# Reference: state and branches

The harness keeps **no hidden state**. Everything it knows is observable from two
places: the branches in git and the files on disk. This page documents both. For
why this design makes the harness safe to leave running, see
[the dispatcher](../concepts/the-dispatcher.md) and the
[design invariants](./invariants.md).

## The branch namespace is the work queue

There is no separate database of "what work exists." The branches *are* the
registry:

| Branch | Role |
|---|---|
| `prd/<author>/<feature>` | `/intent` output — the waiting queue. An atomic rename to `feature/<feature>` is how the harness claims it. |
| `feature/<feature>` | The active implementation lane. |
| `main` | Humans merge here. Never pushed to directly. |
| `learn/<sha>` | Auto-generated memory update from the memory loop. |

Claiming a feature is a single atomic git operation — renaming
`prd/<author>/<feature>` to `feature/<feature>`. If two harnesses ever race for the
same work, whichever pushes the rename first wins and the other moves on. No lock
service, no coordination daemon — git refs are the lock.

By default each developer's harness watches only their own `prd/<my-slug>/*` queue,
so your harness is your personal assistant, not a shared teammate.

## Worktrees

The harness never touches your checkout. It does all its work in **sibling
worktrees** it creates and tears down itself, named `<env>-harness-<feature>`. Your
uncommitted work is structurally out of its reach. The worktree is set up by
`scripts/bootstrap-worktree.sh`, which also re-links the skill symlinks (they are
wiped with the worktree on each tick).

## On-disk layout

Following the [two-tier architecture](../concepts/two-tier-architecture.md):

### Harness repo (tier 1)

```
bin/context-specs        the CLI
scripts/                 the dispatchers (poll-and-dispatch.sh, learn-dispatch.sh, harness-lib.sh)
skills/                  canonical skills (symlinked into environments)
state/<env>/             per-environment runtime state (logs, locks, supervisor bookkeeping)
environments.toml        the registry of registered environments
```

### Environment repo (tier 2)

```
AGENTS.md                the eager contract (a map into the Expert)
.claude/skills/intent/   project-owned /intent (committed)
.claude/skills/expert/   long-term memory (committed)
.claude/skills/*         canonical skills (symlinked, gitignored)
scripts/                 bootstrap-worktree.sh, local-checks.sh
prds/<feature>/          prd.md + run-prd-test.sh
specs/<feature>/         mainspec.md + slices/ (short-term memory)
evals/                   captured regression checks over skills and context
.harness/env             this environment's dials
```

## Related

- [The dispatcher](../concepts/the-dispatcher.md) — reads this state fresh each
  tick.
- [Design invariants](./invariants.md) — the properties this layout guarantees.
- [Reference: the CLI](./cli.md) — the commands that operate on this state.
