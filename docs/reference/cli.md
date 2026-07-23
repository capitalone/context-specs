# Reference: the `context-specs` CLI

`context-specs` is the deterministic half of the harness — the CLI that scaffolds a
harness, registers environments, symlinks the canonical skills into them, and
supervises the dispatcher loops. It contains no LLM; it only schedules
[the dispatcher](../concepts/the-dispatcher.md) (`scripts/poll-and-dispatch.sh`).

It is installed globally (`npm i -g context-specs`) and holds no state. The harness
it acts on is resolved per invocation:

1. `CONTEXT_SPECS_HOME` if set — the dispatchers export this when they call back into
   the CLI.
2. Otherwise, walking up from the current directory: the first ancestor that is a
   harness (`.context-specs/manifest.json`), **or** a registered environment repo,
   which points home through the skill symlinks `add` created.
3. Otherwise an error. The CLI never guesses.

Tier 2 is why you can drive the harness from inside a project. It depends on
`context-specs add` having run for that repo; if it hasn't, the error says so.

```
Usage: context-specs <command> [args]
```

Run `context-specs --help` for the built-in summary.

## Setup

| Command | Description |
|---|---|
| `init [name]` | Scaffold a harness repo (in `name`, or the current directory) and vendor the canonical skills, subagents and dispatchers into it. It becomes your own git repo — no `upstream`, no fork. See [Create a harness](../how-to/create-a-harness.md). |
| `add <path> [--name n]` | Register an environment repo: symlink skills, write `.gitignore` entries, add it to `environments.toml`. Then run `/env-init` inside it. See [Add an environment](../how-to/add-an-environment.md). |
| `update [--force]` | Re-vendor from the installed package version, 3-way merging your local edits against it. Writes `.context-specs/update-report.md` and hands off to `/update-harness`. Refuses on a dirty tree or a live supervisor. See [Update a harness](../how-to/update-a-harness.md). |
| `remove <name>` | Unregister an environment (leaves its files and state in place). |
| `link <path>` | (Re-)create the skill/agent symlinks in a repo or worktree. Idempotent; called automatically by `bootstrap-worktree.sh`. |

## Run

| Command | Description |
|---|---|
| `start [name\|--all]` | Start the background supervisor (build loop + memory loop). |
| `stop [name\|--all]` | Stop the supervisor. |
| `run [name] [--learn]` | One foreground tick, drained to idle. No daemon. `--learn` runs the memory loop instead of the build loop. One environment only — `--all` is rejected. |
| `status [--fetch]` | One-shot table: **every** environment's features and phases — a fleet view, never narrowed by where you stand. `--fetch` updates refs first. Applies the dispatcher's liveness gate (no merged/closed features). |
| `logs [name] [-f] [--learn\|--supervisor]` | Show (or follow) an environment's logs. One environment only. |

### Which environment a command acts on

`start`, `stop`, `run` and `logs` pick a target the same way:

1. the name you gave;
2. `--all` (`start`/`stop` only — `run` and `logs` act on one environment and reject it);
3. the environment you are standing in, or one of its worktrees;
4. your only registered environment;
5. otherwise an error listing your environments.

Anything inferred is announced on stderr (`targeting 'app' (inferred from your current
directory)`), so a bare command never acts on something you didn't expect.
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
