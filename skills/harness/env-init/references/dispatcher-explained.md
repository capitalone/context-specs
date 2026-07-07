# The dispatcher, explained

When you explain the harness to the user, walk them through the dispatcher
using this file. The goal: the user understands every section well enough to
decide whether to tweak it (in the **harness repo** — the dispatcher is tier 1,
shared by every environment). Never present it as a black box.

## What it is

`<harness-repo>/scripts/poll-and-dispatch.sh <env-path> [env-name]` — bash,
`git`, and `gh`. No LLM in the decision path. It runs once per tick, invoked by
the `context-specs` supervisor (or by hand via `context-specs run`). The
`if/elif` chain is the state machine; the artifacts on disk are the state. It
operates on the environment entirely through `git -C <env-path>` (refs,
fetches, pushes, sibling worktrees) and keeps its runtime state in the harness
repo under `state/<env>/`.

**The exit code is the scheduling protocol:**

| Exit | Means | The supervisor does |
|------|-------|---------------------|
| `0`  | idle — no transitions (includes STUCK-only ticks) | sleep the interval (default 5m) |
| `10` | advanced — at least one transition happened | re-invoke IMMEDIATELY (drain) |
| else | error | exponential backoff, capped at 1h |

Drain-on-10 is why a claimed PRD marches through planning → validate →
implement at machine speed instead of one step per 5 minutes; idle polling
stays cheap. STUCK deliberately exits 0 — a stuck environment must never
hot-loop.

## The seven load-bearing properties

Explain these as the "why it's safe" of the script. Each maps to an invariant.

1. **One transition per tick per branch.** The `if/elif` fires at most one
   branch. Next tick, the artifact this tick wrote satisfies the condition and
   the *next* `elif` fires. Forward, one step at a time. (Inv 5)
2. **Artifacts are the only state.** A sentinel existing IS that phase being
   done. No checkpoint file. Crash recovery is free — next tick re-derives from
   disk. (Inv 1 + 4) Most sentinels are written by the skills; `specs/<f>/.prd-passed`
   is the exception — the *dispatcher* commits+pushes it the first time
   `run-prd-test.sh` exits 0, so a runner that shells out to an LLM-as-judge runs
   once instead of every tick (and can't non-deterministically re-kick implement).
3. **Wipe + HEAD-check before every advance.** `git reset --hard && git clean
   -fd` discards a crashed skill's uncommitted mess; the HEAD guard skips any
   worktree whose branch doesn't match the feature being advanced, so a
   manually-checked-out branch is never clobbered. Runs only in per-feature
   worktrees — never in the developer's clone. (Inv 3 + 6)
4. **Dispatcher never invokes an LLM directly.** It only spawns `claude -p`
   subprocesses or shells to `git`/`gh`. Each subprocess is a fresh process and
   a clean context window. (Inv 5)
5. **Local checks are optional and bounded.** If the environment has
   `scripts/local-checks.sh`, the PR is gated on it with a two-strike retry
   (auto-fix, then focused LLM fix, then stop). No script = gate skipped. (Inv 8)
6. **`MAX_WORKTREES` is the one concurrency knob.** Default 1 = FIFO single
   worktree. Claims are lazy: PRDs over capacity stay in `prd/<slug>/*` as the
   visible queue. In-flight work always continues regardless of cap changes.
   (Inv 2 + 3)
7. **Convergence has its own exit — HUMAN_REVIEW — separate from STUCK.** The
   review loop's healthy end is the reviewer posting `REVIEW_CLEAN_MARKER`;
   `reviewer_converged` sees it and writes `human-review-<f>`, the guard posts the
   session trail once and halts the feature for the human's `/evaluate-pr`. The
   marker (not sticky review state) is the signal, so a clean PR can't false-STUCK
   on a stale `COMMENTED` review. If the reviewer never marks clean, the feedback
   cap STUCKs instead — fine, the human merges.

## Section-by-section map

| Section | What | Tweakable? |
|---------|------|------------|
| derivation block | `ENV_PATH`, `ENV_NAME`, `STATE_DIR`, `WORKTREE_BASE`, `TRANSITIONS` | No — the argv contract the supervisor calls. `WORKTREE_BASE` derives from the env's path, so per-feature paths are `<env>-harness-<feature>` siblings. |
| `flock -n` | per-env lock on `state/<env>/tick.lock` | No — serializes ticks per environment; the script is shared, so the lock must not be. |
| config | `SLUG`, `WATCH`, caps, marker | Via the env's committed `.harness/env`, not by editing here. |
| `has_prd()` | Invariant-2 ownership filter | No — defines what "harness-owned" means. |
| step 1 | re-attach in-flight worktrees | The `bootstrap_worktree` hook call is the provisioning hook (see below). The PR-state **liveness gate** (skip `MERGED`/`CLOSED` features) is load-bearing — don't drop it; see "Liveness" below. |
| step 2 | lazy claim up to capacity | No — atomic rename is the claim lock. |
| step 3 | advance each feature one step | **This is where you add/remove pipeline steps** — one `elif` per step. |
| step 4 | cleanup merged/closed PRs (worktree + local branch + counters) | Safe to extend (e.g., notify on cleanup). |
| exit block | `TRANSITIONS > 0 → exit 10` | No — it IS the supervisor protocol. New steps that advance work should bump `TRANSITIONS` (run_claude does it for you). |
| post-merge `/learn` | **NOT in this script** — runs in the separate memory loop (`learn-dispatch.sh`). See "The memory loop" below. | Watermark/idempotency live there. |
| helpers (shared) | `run_claude` (session-tagged invocation + TSV log + transition count), `render_sessions_table`, `ghe` (gh-in-the-env), `worktree_for`, `bootstrap_worktree` — live in `harness-lib.sh`, both loops use them. | Edit `run_claude` in one place (e.g. the `--session-id` swap). |
| helpers (dispatcher) | `signal_stuck`, `signal_human_review`, `reviewer_converged`, `has_prd` | Used by §3 steps that call `claude -p`, hit a cap, or detect convergence. |

One wrapper deserves a callout: **every `gh` call goes through `ghe()`**, which
runs gh with the *environment* as cwd. gh resolves "which GitHub repo" from its
working directory, and the dispatcher's cwd is the harness repo — the wrong
repo. A bare `gh` call here would silently act on the harness repo and its
`2>/dev/null` guard would hide it. Keep new gh calls behind `ghe`.

## The bootstrap hook — environment-owned worktree provisioning

A bare worktree has no `node_modules`, no `.env`, no generated code — **and no
tier-1 skill symlinks** (gitignored symlinks never materialize in new
worktrees) — so slice signals and the PRD runner would fail for reasons
unrelated to the feature. So immediately after every `git worktree add`, the
dispatcher runs the environment's `scripts/bootstrap-worktree.sh "$wt"` if it
exists and is executable, exporting `CONTEXT_SPECS_HOME` so the script's
deterministic header can call `context-specs link` on the new worktree. The
hook itself is canonical; the script it calls is **environment-owned** —
env-init generates it per project (see `worktree-bootstrap.md`).

Make sure the user knows: this hook is why the per-feature worktrees the
harness spins up are actually runnable *and* have their skills.

## Liveness — branch existence is not in-flight (the step-1 PR-state gate)

`has_prd()` answers *ownership* ("is this a harness feature?"), not *liveness*
("is there still work to do?"). A `feature/<f>` whose PR has **merged** keeps both
its branch (GitHub's delete-on-merge is off by default) and its committed PRD —
so `has_prd()` stays true forever. Without a liveness check, step 1 re-attaches
that finished feature as in-flight on *every* tick: step 3 re-fires
`/address-feedback` on the merged PR (wasted tokens), and the phantom occupies a
`MAX_WORKTREES` slot so a fresh PRD sits unclaimed. The fix is one gate in step
1, right after `has_prd`: `ghe pr view` the feature's PR and `continue` past any
`MERGED`/`CLOSED` one. Notes:

- **No branch deletion on the remote.** The harness stops treating it as live
  work; consumers keep their branch-retention policy. (The *local* branch in the
  developer's clone IS deleted at cleanup — worktree-add created it, and a stale
  one would collide when a feature name is reused.)
- **Fail-safe on empty state.** A feature in a pre-PR phase has no PR, and a
  transient `gh` outage also returns empty — both are kept in-flight so live
  work is never silently dropped.
- **Forward-only (Inv 9).** Merged is terminal; the gate only skips, never rewinds.

## How the dispatcher stays fresh (no tick wrapper anymore)

Earlier revisions installed the dispatcher *inside* each project and needed a
wrapper (`harness-tick.sh`) to resync it every tick without overwriting its own
running file. The two-tier split dissolves all of that: the dispatcher lives in
the harness repo and never operates on the repo containing its own bytes.
Updating it is ordinary tool hygiene — `git pull upstream` in the harness repo
(or `context-specs` updates), applied between ticks. Feature **pipeline** skills
never needed a sync at all: they run inside per-feature worktrees that branch
from the PRD branch, so new features pick up skill updates on their own.

## The memory loop — `/learn` as its own loop (`learn-dispatch.sh`)

`/learn` is **not** a dispatcher step. It runs in a second, independent loop the
supervisor schedules on its own interval (default 10m):
`scripts/learn-dispatch.sh <env-path>`. This is the deliberate decoupling that
keeps a multi-minute Expert bootstrap from blocking (or being blocked by) the
build loop. The two loops share nothing but git (Inv 1 + 7): separate locks
(`state/<env>/learn.lock` vs `tick.lock`), separate worktrees.

What `learn-dispatch.sh` does each tick:

1. `flock -n` its own per-env lock (a long bootstrap just no-ops later ticks).
2. `git -C <env> fetch` `main` **and** the watermark ref namespace
   (`+refs/harness/*:refs/harness/*`). Refs only — never a working tree.
3. **Pause** if a `learn/<sha>` PR is already open (`ghe pr list …`): memory
   edits serialize behind human review. Nothing is queued — the backlog is
   implicit in `(watermark, origin/main)` and recomputed every tick.
4. Compute `since = refs/harness/last-learned` (or a bounded look-back on the
   first run), `to = origin/main`; if equal, no-op.
5. `git ls-remote origin learn/<to>` idempotency (cross-node first-to-push-wins).
6. Ensure the dedicated, **reused** `<env>-harness-learn` worktree exists
   (create + `bootstrap_worktree` on first run), re-run `context-specs link` on
   it (persistent worktree, evolving skill set), reset it to clean
   `origin/main`, check out `learn/<to>`.
7. Run `/learn --since <since> --sha <to>` there. `/learn` writes memory,
   pushes the branch, opens the PR.
8. `signal_learn_review` posts the session trail on the PR (if one opened).
9. Advance `refs/harness/last-learned` to `<to>` with an atomic CAS
   (`--force-with-lease`) — the same first-to-push-wins primitive used to claim
   PRDs. The advance happens whether or not a PR opened (a no-op merge is still
   "learned").

**Why a ref watermark, not a state file.** A ref lives in its own namespace
nothing cleans, so it survives `learn/<sha>` branch deletion; it's on the
remote, so it's shared across nodes; and `--force-with-lease` gives a lock-free
compare-and-swap. To force a full re-learn: delete the ref or run
`/learn --rebuild` by hand.

## Human-steering points: Evaluate (HUMAN_REVIEW) and STUCK

The human steers the machine at three touchpoints (confirm a PRD,
evaluate-then-merge a PR, unstick a STUCK). Two of those live in this script.

**HUMAN_REVIEW (the healthy one).** When the reviewer converges (posts
`REVIEW_CLEAN_MARKER`), `reviewer_converged` writes `human-review-<f>`; the guard
posts the build-session trail once and halts the feature. The human runs
`/evaluate-pr` to walk the change, run it, and merge (or fix-and-push, or close).
The loop does not re-engage — the human is the last mile.

**STUCK (the failure one).** Memory's automated write path stays post-merge —
`/learn` in the memory loop, always via a reviewable PR (the developer edits
memory directly whenever they like). There is no separate automated write path
for failed features. Instead, **STUCK** (a step in §3 hitting its cap) is a
first-class escalation: the dispatcher posts to the PR (opening it as a draft if
needed) with the session log, the failing output tail, and a pointer to
`/improve-context`, then halts the feature. That skill walks the human through
the diagnosis-first flow: identify the **context defect** (which `AGENTS.md` /
Expert / spec / PRD content misled the agent), correct it on the branch, *then*
fix the code, *then* merge. Those context corrections ride into main with the
merge, where `/learn` picks them up.

## The session log + STUCK signal

`run_claude` and `render_sessions_table` are **shared** (in `harness-lib.sh`);
the rest are dispatcher-local:

- **`run_claude <step> <feature> <attempt#> <wt> "<skill cmd>"`** (shared) —
  wraps every `claude -p` call. `cd`s into the worktree `<wt>` first (there is
  no print-mode `--cwd` flag, and the `cd` is what gives the skill its
  `.claude/` command + `AGENTS.md` discovery). Generates a UUID session id, runs
  `claude -p --session-id "${CLAUDE_PERM_ARGS[@]}"`, bumps the dispatcher's
  `TRANSITIONS` counter, and appends
  `<timestamp>\t<step>\t<attempt>\t<session_id>\t<exit>\t<duration>` to
  `state/<env>/sessions-<feature>.tsv` (cleared on merge/close). A non-zero
  skill exit is recorded in the row but never aborts the tick (`return 0`).
- **`signal_stuck <feature> <step> <cap> [output-file]`** — touches the stuck
  sentinel, composes a PR body (step, cap, session-log tail, optional failing
  output tail, `/improve-context` pointer), and opens a draft PR or comments on
  the existing one. The single human-facing surface for failures.
- **`reviewer_converged <branch>`** — true iff a PR comment contains
  `REVIEW_CLEAN_MARKER`. One `ghe` call, no LLM. Empty marker = no reviewer → false.
- **`signal_human_review <feature>`** — the convergence counterpart: posts the
  "Ready for your review" comment with the session trail for `/evaluate-pr`.
- **`signal_learn_review <feature> <branch>`** — lives in **`learn-dispatch.sh`**:
  after `/learn` opens its `learn/<sha>` PR, posts the headless session trail
  framed for troubleshooting *why* `/learn` routed each fact as it did.

If your `claude -p` version doesn't support `--session-id`, swap that flag for
`--output-format json` and parse `session_id` from stdout — `run_claude` is the
one place to change.

## Common tweaks to offer

- **Add a pipeline step** (e.g. `/security-review` between validate and
  implement): insert one `elif` in step 3 with its own sentinel check, its own
  `<step>_CAP`, and a `run_claude` / `signal_stuck` pair like the others.
  Remember this edits the harness repo — every environment gets the new step.
- **STUCK caps**: `PLANNING_CAP`, `VALIDATE_CAP`, `IMPLEMENT_CAP`,
  `LOCAL_CHECKS_CAP`, `FEEDBACK_CAP` — per-environment, in `.harness/env`.
- **Tick cadence**: `INTERVAL` / `LEARN_INTERVAL` env vars on
  `context-specs start`, or a per-env `interval` in `environments.toml`. UX
  knobs, not correctness ones — the loops self-serialize and re-derive state
  every tick.

## What NOT to let the user do

- Add `&` to any `claude -p` call (breaks synchronous one-step discipline).
- Add an LLM call to the decision logic (breaks Inv 5, makes it non-reproducible
  and a cost surface).
- Remove the wipe or the HEAD guard (breaks crash recovery and Inv 6).
- Replace the atomic-rename claim with a marker file (breaks Inv 2 + 7).
- Call `gh` directly instead of `ghe` (acts on the wrong repo, silently).
- Exit 10 from an error path, or bump `TRANSITIONS` at STUCK (either would make
  the supervisor hot-loop a broken environment).
- Fold `/learn` back into the dispatcher as a step — that re-couples the loops,
  so a multi-minute Expert bootstrap again blocks every feature step.
- Make `learn-dispatch.sh` do working-tree ops in the developer's clone instead
  of `<env>-harness-learn` — the developer's tree is never the harness's
  surface (Inv 6).
