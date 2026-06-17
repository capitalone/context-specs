# Invariants to preserve

The harness is safe to leave running because of nine invariants. A new loop inherits them by
cloning the substrate — but only if you don't break them while filling in the namespace.
This is the define-loop-specific reading; the canonical statements live in the project's
design invariants doc.

| # | Invariant | What it means for a new loop |
|---|---|---|
| 1 | **State on disk + branches** | Counters in `.harness/`, sentinels committed to the branch, PR state via `gh`. The new dispatcher re-derives everything each tick. Don't add an in-memory queue. |
| 2 | **Branch namespace IS the registry** | `<ns>/<author>/<f>` = waiting, `feature/<ns>/<f>` = active, merged = done. The atomic rename is the only claim. A `feature/<ns>/<f>` is loop-owned iff `prds/<f>/prd.md` is committed to it. |
| 3 | **Worktree ↔ branch 1:1 per node** | Per-feature worktrees at `<repo>-harness-ns-<ns>-<f>`; the HEAD guard skips a worktree whose branch doesn't match. Never ping-pong one worktree between branches. |
| 4 | **Skill idempotency via write-then-touch** | Reused pipeline skills already satisfy this. Any new phase skill must commit+push its artifacts *before* its sentinel, and converge on re-run. |
| 5 | **Dispatcher discipline** | Zero LLM in the decision path; one step per branch per tick; `claude -p` calls synchronous (no `&`); `flock -n` on `$0`. The new dispatcher's own flock keeps it independent of the other loops. |
| 6 | **Human's checkout is sandboxed** | The loop runs only in its `-ns-` worktrees, never the human's checkout. `/intent-<ns>` is the sole carve-out (human present, consenting). |
| 7 | **Cross-node safety** | Atomic-rename claim + first-to-push-wins. Multiple nodes running this loop contend safely on git refs alone — no coordination service. |
| 8 | **Verification is non-bypassable** | The oracle (`run-prd-test.sh` exit 0) plus `local-checks`/CI decide "done" — never the agent's self-report. Silencing a check = bypassing it. Every loop keeps at least one hard gate. |
| 9 | **Forward-only state machine** | Skills walk forward; no skill un-touches a sentinel. The `.prd-passed` cache is forward-only. Recovery from a wrong plan is human-triggered (refile), not dispatcher-rewound. |

## The define-loop-specific hard rules
- **Add alongside, never modify.** Do not edit `poll-and-dispatch.sh`, the `learn` loop, or
  any shared pipeline skill. Isolation is by namespace; the build loop must stay byte-for-byte
  unchanged (a `git diff` after generation should touch only new paths + `.gitignore`).
- **Own worktree, own flock.** The loop must not run in the build host worktree (Inv 5/6
  interaction — it would race the host sync).
- **No self-learning on loops.** `loops/<ns>/` (oracle rubric, PRD template, learn-lens) and
  the dispatcher are human-owned. `learn` writes namespace-*independent* knowledge only.
- **No eager namespace memory.** Steering lives in phase skills + the PRD template's
  `## Loop conventions`, not in an injected/auto-loaded file.
