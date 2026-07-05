# Config options — `.harness/env`

The harness has a small, deliberately tiny config surface. Per-environment
knobs live in the environment's committed `.harness/env` (sourced by the tier-1
dispatcher on every tick); scheduling knobs live with the CLI. When you walk
the user through config, explain each knob's tradeoff and recommend the
default; only change a default if the user has a concrete reason.

## The knobs (`.harness/env`, committed in the environment)

### `MAX_WORKTREES` (default `1`)

How many features the harness works in parallel *in this environment*.

- **`1` (recommended default).** Single worktree, FIFO. One feature at a time.
  No disk multiplication, simplest mental model. Right for essentially every
  single-developer project. (Parallelism across *environments* is free — each
  has its own supervisor.)
- **`2`+.** Bounded parallelism. Each concurrent feature gets its own sibling
  worktree, so disk and rebuild cost multiply.

In-flight work always continues regardless of this value — it caps *new intake*,
not continuation.

### `WATCH_PATTERN` (default `prd/<your-slug>/*`)

Which PRD branches this harness claims. `<your-slug>` derives from
`git config user.email` (the part before `@`).

| Mode | Pattern | Behavior | When |
|------|---------|----------|------|
| **Per-dev (default)** | `prd/<my-slug>/*` | Each dev's harness claims only their own PRDs, on their own machine, their own API quota. | Default. Best attribution, cost, and observability. |
| **Shared pool** | `prd/*/*` | All harnesses race for everything; atomic rename keeps it safe. | A team deliberately sharing a work pool. |

### STUCK caps

Bounded-retry circuit breakers — every step has one, so the loop can't run away.
At cap, the dispatcher signals STUCK on the PR (opening it as a draft if no PR
exists yet) with the session log + a diagnosis-first checklist, and halts that
feature. A STUCK-only tick exits 0, so a stuck environment never hot-loops.

| Var | Default | Step it bounds |
|---|---|---|
| `PLANNING_CAP` | 2 | `/spec-planning` |
| `VALIDATE_CAP` | 2 | `/spec-validate` |
| `IMPLEMENT_CAP` | 3 | `/implement-mainspec` (PRD runner keeps failing) |
| `LOCAL_CHECKS_CAP` | 2 | `scripts/local-checks.sh` two-strike |
| `FEEDBACK_CAP` | 5 | reviewer feedback rounds |

### `REVIEW_CLEAN_MARKER` (convergence signal)

Default `HARNESS_REVIEW_CLEAN`. When the reviewer has no Important findings left,
`REVIEW.md` instructs it to post a PR comment containing this token; the dispatcher
(`reviewer_converged`) sees it and hands the PR to the human for `/evaluate-pr`.
Detection is intentionally simple — marker present → converge. If the reviewer
never posts it, the feedback loop reaches `FEEDBACK_CAP` and STUCKs instead (a
clean PR the human merges). Set it **empty** when there is **no reviewer**, so
the dispatcher converges at PR-open. Must match `REVIEW.md`.

### `CLAUDE_PERM_ARGS`

Headless permission posture for the `claude -p` subprocesses; see the template's
comments. Default `( --permission-mode auto )`.

## Scheduling knobs (the CLI's, not `.harness/env`)

- **Build interval** — `INTERVAL` env var on `context-specs start`, or a per-env
  `interval` in `environments.toml`. Default 300s. This is only the *idle* poll
  rate: a tick that advanced work (exit 10) re-fires immediately, so real work
  drains at machine speed regardless of the interval.
- **Learn interval** — `LEARN_INTERVAL`, default 600s. The memory loop can tick
  lazily: it only acts when `origin/main` has advanced past the watermark AND no
  `learn/<sha>` PR is open. Most ticks are cheap no-ops.

Both are UX knobs, not correctness ones — the loops self-serialize (per-env
locks) and re-derive their state every tick, so a missed or slow tick never
corrupts anything.

### The memory loop's watermark (`refs/harness/last-learned`)

Not a config value — a git **ref** on the environment's remote, the memory
loop's only durable state. It records how far into `main`'s history `/learn`
has digested. `learn-dispatch.sh` reads it as the `--since` for the next run
and advances it (atomic `--force-with-lease`) after each run. It lives in its
own ref namespace, so it survives `learn/<sha>` branch deletion and is shared
across nodes. To force a full re-learn, delete the ref
(`git push origin :refs/harness/last-learned`) or run `/learn --rebuild` by hand.

## What does NOT go in config

- **The claim mechanism** — the atomic rename, hardcoded. Not configurable.
- **Completion signals** — sentinel files, hardcoded in the dispatcher.
- **The pipeline order** — the `if/elif` chain in the tier-1 dispatcher, edited
  there (see dispatcher-explained.md), not a config value.
- **Where state lives** — always the harness repo's `state/<env>/`.

## Runtime state — `state/<env>/` in the harness repo

Holds per-environment runtime state, all re-derivable, none of it secret, all
gitignored in the harness repo (nothing of it lives in the environment):

- `tick.lock`, `learn.lock` — per-env `flock` files (tick serialization).
- `planning-attempts-<f>`, `validate-attempts-<f>`, `implement-attempts-<f>`,
  `local-check-attempts-<f>`, `feedback-rounds-<f>` — per-feature retry counters
  (each gates a STUCK circuit breaker).
- `stuck-<f>`, `stuck-output-<f>.log`, `stuck-body-<f>.md` — written when a cap
  hits; cleared on merge/close.
- `human-review-<f>`, `human-review-posted-<f>`, `human-review-body-<f>.md` —
  written at reviewer convergence; cleared on merge/close.
- `sessions-<f>.tsv` — every `claude -p` invocation for this feature (timestamp,
  step, attempt, session_id, exit, duration). The STUCK PR body quotes its tail
  so the human can open the trace by session id.
- `supervisor.pid`, `logs/{build,learn,supervisor}.log` — the CLI's.

Deleting this directory is safe (it unregisters nothing): counters reset,
sentinels re-derive from git and PR state on the next tick.

The environment's `.harness/env` is the one committed piece — commit it so a
team's checkouts share defaults.

## Multi-developer reminder

Per-dev is the default for a reason (attribution, cost isolation, "my harness is
my assistant" mental model). The harness *repo* is shareable — a team improves
skills and scripts in one place, while each dev's registry (`environments.toml`)
and state stay per-machine. Don't steer a user to shared-pool claiming unless
they explicitly describe a shared-queue workflow; when a team truly outgrows
local harnesses, the move is a server/CI harness.
