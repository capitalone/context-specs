# Invariants the setup must not break

The harness rests on nine invariants (listed below, each with its setup-time
implication). env-init must not generate anything that violates them — this
is what *you*, running this skill, must be careful about.

| # | Invariant | What it means at setup time |
|---|-----------|------------------------------|
| 1 | **State lives on disk + branches** | Never generate a daemon, a background queue, or a config that caches "current work" in memory. Retry counters go in the harness repo's `state/<env>/`; sentinels are committed to the feature branch. |
| 2 | **Branch namespace IS the registry** | The claim is the atomic rename `prd/<author>/<f>` → `feature/<f>`. Do not add a `.claimed` marker or a lock service. A `feature/<f>` is harness-owned **iff** `prds/<f>/prd.md` is committed to it. |
| 3 | **Worktree ↔ branch is 1:1** | Each feature gets its own sibling worktree `<env>-harness-<feature>`. Never generate logic that switches one worktree between branches. |
| 4 | **Skill idempotency (write-then-touch)** | Sentinels are written *after* artifacts are committed. The dispatcher checks only the sentinel. Don't add completion checks based on partial artifact presence. |
| 5 | **Dispatcher discipline** | Zero LLM calls in the dispatcher. One step per branch per tick. `claude -p` invocations are synchronous, never backgrounded with `&`. Ticks serialize per environment on `state/<env>/tick.lock` (`flock -n`), and the exit code is the whole scheduling protocol (0 idle / 10 advanced / else error). The build loop and the memory loop (`learn-dispatch.sh`) are two independent loops with separate locks and separate worktrees, so neither blocks the other; they coordinate only through git (the `refs/harness/last-learned` watermark + `ls-remote` idempotency on `learn/<sha>`). |
| 6 | **The developer's working tree is sandboxed** | THE TRUST INVARIANT. The harness operates on the environment only through its *refs* (`git -C <env> fetch/push`) and through *sibling worktrees* — it never touches the developer's checked-out files. env-init may write/commit setup files in the checkout (the developer is present and consenting), but the running harness never does. `bootstrap-worktree.sh` copies secrets FROM the developer's checkout INTO worktrees — never the reverse, never deletes. |
| 7 | **Cross-node safety** | Safety comes from atomic git ref ops + `ls-remote` idempotency checks, not coordination services. Keep those primitives even when N=1 — they cost nothing and are the upgrade path. |
| 8 | **Verification is non-bypassable** | The dispatcher cannot vouch for "done"; only `run-prd-test.sh` exit 0 + CI gates can. Never generate a path that opens/merges a PR without the runner passing. `local-checks.sh` is an *additional* gate, not a replacement. Caching the first green run in `specs/<f>/.prd-passed` is **not** a bypass — the runner still ran and passed; don't "optimize" by skipping the run before the sentinel exists. |
| 9 | **Forward-only state machine** | Skills walk forward; none un-touches another's sentinel. Recovery from a wrong plan is human-triggered (delete branch, refile PRD), never a dispatcher rewind. Don't generate "go back a step" logic. |

## The single most important one

**Invariant 6.** If a developer ever fears the harness will stomp their
uncommitted work, the whole design loses their trust regardless of how clean it
is. The two-tier split makes this structural — the dispatcher lives in the
harness repo and only ever runs `git -C <env>` ref operations plus sibling
worktrees — but what you *generate* must uphold it too. When the skill explains
anything that writes to disk, be explicit about *where* it writes. The
secret-copying step in `bootstrap-worktree.sh` is the one place the skill
touches sensitive files — flag it loudly and get explicit consent.

## Mode independence

These invariants hold for local laptop, server, and CI alike. env-init sets up
the *local* mode today, but must not generate anything that would have to be
torn out to move to server/SDK mode later. Concretely: keep the cross-node
primitives, keep state on disk, keep the dispatcher LLM-free.
