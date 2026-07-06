# Reference: the `context-specs` CLI

`context-specs` is the deterministic half of the harness — the CLI that registers
environments, symlinks the canonical skills into them, and supervises the
dispatcher loops. It contains no LLM; it only schedules
[the dispatcher](../concepts/the-dispatcher.md) (`scripts/poll-and-dispatch.sh`).

```
Usage: context-specs <command> [args]
```

Run `context-specs --help` for the built-in summary.

## Setup

| Command | Description |
|---|---|
| `init [name]` | Create (or adopt) a harness repo from the context-specs template. See [Create a harness](../how-to/create-a-harness.md). |
| `add <path> [--name n]` | Register an environment repo: symlink skills, write `.gitignore` entries, add it to `environments.toml`. Then run `/env-init` inside it. See [Add an environment](../how-to/add-an-environment.md). |
| `remove <name>` | Unregister an environment (leaves its files and state in place). |
| `link <path>` | (Re-)create the skill/agent symlinks in a repo or worktree. Idempotent; called automatically by `bootstrap-worktree.sh`. |

## Run

| Command | Description |
|---|---|
| `start [name\|--all]` | Start the background supervisor (build loop + memory loop). |
| `stop [name\|--all]` | Stop the supervisor. |
| `run [name] [--learn]` | One foreground tick, drained to idle. No daemon. `--learn` runs the memory loop instead of the build loop. |
| `status [--fetch]` | One-shot table: every environment's features and phases. `--fetch` updates refs first. Applies the dispatcher's liveness gate (no merged/closed features). |
| `logs <name> [-f] [--learn\|--supervisor]` | Show (or follow) an environment's logs. |
| `doctor` | Check the harness, the registry, and every environment. |

See [Run the harness](../how-to/run-the-harness.md) for usage.

## The scheduling protocol: exit codes

The CLI schedules the dispatcher and reacts to its exit code — that is the entire
protocol:

| Exit code | Meaning | Supervisor reaction |
|---|---|---|
| `0` | Idle — no work advanced | Sleep the interval (default 5 min), then tick again |
| `10` | Work advanced | Re-invoke immediately, until the environment is idle |
| non-zero (other) | Error | Back off exponentially |

A STUCK feature reports idle, so a stuck environment never hot-loops.

## Related

- [The dispatcher](../concepts/the-dispatcher.md) — the deterministic engine this
  CLI drives.
- [Reference: state and branches](./state-and-branches.md) — where the CLI's state
  lives.
- [Reference: skills](./skills.md) — the probabilistic half the CLI hands off to.
