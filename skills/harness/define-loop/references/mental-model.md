# Mental model — what define-loop builds

Read this first. Narrate from it; the user has likely never thought of the harness as
something with *multiple* loops.

## One sentence
`define-loop` adds a new **intent-sourced namespace loop** that runs the same
plan→validate→implement→verify→PR cycle as the `prd` build loop, on its own branch
namespace and its own worktrees, differentiated only by its minter, its PRD template, and
its oracle.

## One substrate, many minters
The harness's safety comes from a substrate that is already namespace-agnostic — the nine
invariants, realized in `poll-and-dispatch.sh` and the shared `harness-lib.sh`:
claim-by-atomic-git-op, worktree↔branch 1:1, write-then-touch sentinels, one-step-per-tick,
bounded-retry→STUCK, forward-only, non-bypassable oracle. The `prd` build loop is just the
*first* program running on that substrate.

A **minter** turns a source-event into a claimable git work-item that carries an **oracle**
(a runnable definition of done). `/intent` is the minter for `prd/`. `define-loop` generates
*another* minter (`/intent-<ns>`) and its loop. Everything that differs between loops is the
front-end (minter + PRD template + oracle) and the namespace; the substrate is identical and
reused.

## The three-layer stack (same as the build loop)
```
OUTER LOOP    a /loop 5m /<ns>-loop session. Owns TIMING only.
  v
TICK WRAPPER  scripts/<ns>-tick.sh. Syncs this loop's infra worktree to clean origin/main,
  v           then execs the dispatcher. Keeps loop infra fresh.
DISPATCHER    scripts/<ns>-dispatch.sh. Pure bash, zero LLM. Owns ROUTING: reads disk,
  v           decides the next skill per branch, shells out. The if/elif chain IS the state machine.
INNER LOOP    one fresh claude -p "/skill ..." per step. Owns THE WORK.
```

## Worktree topology — why this loop needs its OWN infra worktree
```
<repo>/                              human's checkout. Never touched. (Inv 6)
<repo>-harness/                      build loop's host worktree (detached at origin/main).
<repo>-harness-<feature>/            build loop's ephemeral per-feature worktrees.
<repo>-harness-learn/                memory loop's dedicated worktree.
<repo>-harness-ns-<ns>/              THIS loop's infra worktree (detached at origin/main),
                                     synced each tick by <ns>-tick.sh under its own flock.
<repo>-harness-ns-<ns>-<feature>/    THIS loop's ephemeral per-feature worktrees.
```
An intent-loop spawns *per-feature* worktrees (parallel features) like the build loop —
unlike `learn`, which reuses one worktree. If it shared the build loop's host worktree it
would race that loop's per-tick force-sync. So it gets its **own** infra worktree + its own
flock (the dispatcher's `flock -n` on `$0`). Multiple detached worktrees at `origin/main` are
allowed — git only forbids two worktrees on the same *checked-out branch*; detached HEADs are
fine. The **`-ns-` infix** keeps `<repo>-harness-ns-bug` from colliding with a build-loop
feature literally named `bug` (`<repo>-harness-bug`).

## Where the human steers (unchanged)
1. Mint a work-item (`/intent-<ns>`, in their checkout).
2. Merge a PR (after `/evaluate-pr`, or after unsticking a STUCK).
The loop never merges. Everything between mint and merge is the loop.

## What define-loop does NOT touch
The `prd` build loop, the `learn` memory loop, and every pipeline skill (`/spec-planning`,
`/spec-validate`, `/implement-mainspec`, `/address-feedback`, `local-checks.sh`) are reused
**unchanged** — they're path-based (`prds/<f>/`, `specs/<f>/`), so they run in a
`feature/<ns>/<f>` worktree exactly as they do for `prd`. define-loop only adds new files.
