# Design invariants

This is the reference companion to the [documentation overview](../overview.md) —
specifically [The dispatcher](../concepts/the-dispatcher.md), which
gives you the intuition for why the harness is safe to leave running. This
document gives you the *proof*: it enumerates the properties the harness holds no
matter what crashes, races, or restarts.

**Who it's for.** Primarily **you, the human**, when you want a rigorous model of
why the autonomous loop is trustworthy — before you rely on it, extend the
dispatcher, or debug a stuck branch. It's optional reading; the chapters stand on
their own. You can also hand this file to an agent when you want it to reason
about the harness with a deeper understanding of the guarantees it must not
break.

---

## Contents

- [§ 1 — Preamble](#-1--preamble)
- [§ 2 — The invariants](#-2--the-invariants)
  1. [State lives on disk + branches](#invariant-1--state-lives-on-disk--branches)
  2. [Branch namespace IS the work registry](#invariant-2--branch-namespace-is-the-work-registry)
  3. [Worktree ↔ branch is 1:1 per node](#invariant-3--worktree--branch-is-11-per-node)
  4. [Skill idempotency via write-then-touch](#invariant-4--skill-idempotency-via-write-then-touch)
  5. [Dispatcher discipline](#invariant-5--dispatcher-discipline)
  6. [The developer's working tree is sandboxed](#invariant-6--the-developers-working-tree-is-sandboxed)
  7. [Cross-node safety](#invariant-7--cross-node-safety)
  8. [Verification is non-bypassable](#invariant-8--verification-is-non-bypassable)
  9. [Forward-only state machine](#invariant-9--forward-only-state-machine)
- [§ 3 — Local vs server side-by-side](#-3--local-vs-server-side-by-side)
- [§ 4 — Live trade-offs (what's a choice, not a law)](#-4--live-trade-offs-whats-a-choice-not-a-law)
- [§ 5 — Failure-mode walkthroughs](#-5--failure-mode-walkthroughs)

---

## § 1 — Preamble

An **invariant** here is a property the system must maintain regardless of crashes, restarts, concurrent operations, or which OS-level substrate (local laptop, server, GitHub Actions runner) is providing execution. Invariants are mode-independent statements; the enforcement mechanism is allowed to vary.

**Who enforces what:**

- **The dispatcher script** enforces structural invariants: claim atomicity, worktree-branch mapping, one-step-per-tick, lazy-claim under capacity, cross-node safety primitives.
- **The skills** enforce idempotency + commit-then-sentinel ordering. Without this, recovery breaks.
- **Humans** enforce the merge gate and the PRD-runner authorship. The dispatcher can invoke `run-prd-test.sh` and observe exit codes; only humans approve merges; only human-reviewed PRs change the runner itself.

**When to consult what:**

| If you're… | Read… |
|---|---|
| Adding a new skill to the pipeline | § 2 invariants 4, 5, 9 |
| Changing the dispatcher script | § 2 all, plus § 4 trade-offs |
| Upgrading from local to server | § 3 side-by-side table |
| Debugging a stuck or recovering branch | § 5 failure walkthroughs |
| Picking config (MAX_WORKTREES, counter strategy, etc.) | § 4 |

---

## § 2 — The invariants

### Invariant 1 — State lives on disk + branches

**Statement.** Everything the dispatcher needs to decide what runs next must be observable from `git` and the local filesystem. No daemon, no in-memory queue, no process-scoped variable that persists across ticks.

**Why it matters.** This is the only reason crash-recovery is free. `kill -9` mid-skill leaves zero garbage the next tick can't sort out by re-reading disk.

**What breaks if violated.** Any "I'm currently working on X" cached in process memory introduces a state-mismatch failure mode the wipe-and-re-derive model can't fix. The script becomes non-recoverable.

**How it's enforced.**

- Retry counters and runtime sentinels live in the harness repo's
  `state/<env>/` files (per-environment, gitignored, safely wipeable).
- Pipeline sentinels are committed to the feature branch.
- PR state is observed via `gh pr view` (run with the environment as cwd).
- The dispatcher reads everything fresh at the start of every tick.

### Invariant 2 — Branch namespace IS the work registry

**Statement.** Every branch belongs to exactly one state (`prd/<author>/<f>` = waiting, `feature/<f>` = active, merged-to-main = done, `learn/<sha>` = memory review). Atomic git ref operations are the only state-transition primitive. A `feature/<f>` branch is **harness-owned iff `prds/<f>/prd.md` is committed to it**.

**Why it matters.** No advisory locks, no `.claimed` markers, no separate coordination service. The set of branches on origin IS the queue, the lock service, and the assignment record — all by themselves.

**What breaks if violated.** A non-git claim mechanism introduces a second source of truth that can disagree with branch state. The single-source-of-truth property dies.

**How it's enforced.**

- The atomic rename `prd/<author>/<f>` → `feature/<f>` is the claim. Push fails non-fast-forward = you lost; exit cleanly.
- The dispatcher's `has_prd()` check (`git cat-file -e origin/feature/<f>:prds/<f>/prd.md`) is the harness-owned filter. Hand-pushed `feature/quickfix` without a PRD is ignored.
- The only way a `feature/*` exits "active" state is the cleanup pass observing PR merged/closed.

### Invariant 3 — Worktree ↔ branch is 1:1 per node

**Statement.** At any moment, every worktree's HEAD matches the feature branch that worktree exists to work on. Parallelism is opt-in by adding worktree paths, not by switching one path between branches.

**Why it matters.** A worktree that ping-pongs between branches between iterations makes "what branch is the harness working?" a question about wall-clock time, not disk state. Observability collapses.

**What breaks if violated.** Branch-switching a single worktree (the pre-refactor bug) causes work on branch A to get clobbered by work on branch B mid-tick, and vice versa.

**How it's enforced.**

- Worktree paths are per-feature siblings of the environment's clone:
  `<env>-harness-<feature>` (derived from the environment's path).
- The advance loop verifies `git rev-parse --abbrev-ref HEAD` matches the iterated branch before acting; skip if not.
- The `MAX_WORKTREES` env var caps concurrent worktrees; >1 = parallelism opt-in.

### Invariant 4 — Skill idempotency via write-then-touch

**Statement.** Skills commit + push all required artifacts *before* writing their sentinel. The sentinel is the only completion signal the dispatcher uses. Re-running a skill on partial-but-committed state must converge to the same end-state.

**Why it matters.** A crash between artifact-commit and sentinel-write rolls back to "this skill hasn't completed yet." The next tick re-invokes it, which must produce the same result.

**What breaks if violated.** A skill that uses sentinel-presence-without-artifacts as a shortcut (or vice versa) breaks recovery. A non-idempotent skill creates divergent outcomes across re-runs.

**How it's enforced.**

- The dispatcher reads only the sentinel file as the completion check (never partial artifact presence).
- Skills `touch specs/<f>/.planning-done` (etc.) as their final commit-and-push.
- The wipe at the top of each advance iteration (`git reset --hard && git clean -fd`) clears any uncommitted partial state from a crashed skill.

**Loose end.** `/spec-validate` consensus is genuinely non-deterministic across re-runs (3 LLM subagents may vote differently). Projects needing reproducibility pin model + seeds inside the skill.

### Invariant 5 — Dispatcher discipline

**Statement.** The dispatcher contains zero LLM calls. It executes at most one skill step per branch per tick. Skill invocations (`claude -p`) within a tick are synchronous and sequential. Its entire scheduling interface is its exit code: `0` = idle, `10` = advanced (the supervisor re-invokes immediately — a *drain*, not a second step within the tick), anything else = error.

**Why it matters.** A dispatcher with LLM in the decision loop is non-reproducible and inflates context cost. Multi-step-per-tick makes "what will the next action be?" unanswerable from disk state. The exit-code protocol keeps the supervisor equally deterministic — it holds no opinion about the work, only about *when* to ask again.

**What breaks if violated.** Embedding `claude -p` in the dispatcher's decision logic makes the dispatcher itself a cost surface. Allowing skill chaining within a tick makes the state machine harder to debug. Exiting `10` from an error path (or from a STUCK-only tick) makes the supervisor hot-loop a broken environment.

**How it's enforced.**

- The dispatcher script is pure bash + `git` + `gh`. No `claude -p` outside the skill-invocation positions.
- The if/elif chain in the advance loop fires at most one branch per iteration.
- `claude -p` invocations are blocking; no `&` backgrounding.
- `flock -n` on the per-environment lock (`state/<env>/tick.lock`) prevents overlapping ticks for the same environment. The lock is per-env, not on the script — the script is shared by every environment, and environments must not serialize against each other.
- A `TRANSITIONS` counter (bumped by `run_claude`, the PRD claim, the PR open, the auto-fix commit, and the `.prd-passed` sentinel) drives the final exit; STUCK paths never bump it, so a stuck environment reports idle.
- The build loop and the memory loop (`learn-dispatch.sh`) are two independent loops with separate locks and separate worktrees; they coordinate only through git.

### Invariant 6 — The developer's working tree is sandboxed

**Statement.** The harness never touches the developer's checked-out files. It operates on the environment's clone only through *ref* operations (`git -C <env> fetch/push/for-each-ref/cat-file`) and through *sibling worktrees* it creates and tears down itself. `/intent` is the sole carve-out, justified by being a synchronous conversational skill the developer runs themselves, attentively, in their own checkout.

**Why it matters.** This is the trust invariant. If the harness ever stomps WIP, social trust in the design collapses regardless of how clean the technical model is.

**What breaks if violated.** Possibility of clobbering uncommitted work mid-edit. Even if it never actually happens, the user can't trust it won't.

**How it's enforced.**

- The dispatcher lives in the **harness repo**, not the environment — there is no harness code inside the project to run "in place," and its cwd is never the developer's checkout.
- Every environment operation is either a ref op (fetch, push, cat-file, for-each-ref — none touch a working tree) or scoped to a `<env>-harness-*` sibling worktree (`git -C "$wt"`, `cd "$wt"`). The wipe/reset/clean commands run only inside per-feature worktrees.
- The one filesystem write into the environment's checkout is the gitignored `.claude/` symlinks — created by `context-specs add`/`link`, which the developer runs themselves.
- `bootstrap-worktree.sh` copies secrets FROM the developer's checkout INTO worktrees — never the reverse, never deletes.
- Worktree creation does add refs to the shared `.git` (a local `feature/<f>` branch appears in the developer's `git branch` output, and is deleted again at cleanup) — ref noise, by design never working-tree changes.

In server mode this invariant becomes trivial (no developer checkout on the server — the "clone" is the harness's own). It remains stated because the invariants are mode-independent.

### Invariant 7 — Cross-node safety

**Statement.** Any number of harnesses may run concurrently against the same origin. They must contend safely on git refs alone; no external coordination service.

**Why it matters.** The whole upgrade story (single laptop → multiple laptops → server) depends on this being free. The local-vs-server gap closes only if both modes work for any N ≥ 1.

**What breaks if violated.** If safety needs a coordination service, server upgrade requires deploying that service. If safety needs in-process state, two laptops can race. Either way, the model breaks down.

**How it's enforced.**

- Atomic-rename claim (Invariant 2).
- `git ls-remote origin learn/<sha>` pre-flight idempotency check.
- Worktree-HEAD guard (Invariant 3) ensures only the node owning a worktree advances its branch.

### Invariant 8 — Verification is non-bypassable

**Statement.** The dispatcher cannot vouch for "done." Only `./prds/<f>/run-prd-test.sh exit 0` plus project CI gates can. Humans override only by editing the runner, which is PR-reviewed.

**Why it matters.** The PRD runner is the single load-bearing contract for "this feature does what was asked." If the agent can talk past it, every other guarantee dissolves.

**What breaks if violated.** A dispatcher path that merges a PR without invoking the runner, or that proceeds despite non-zero exit, makes "done" a matter of agent self-report.

**How it's enforced.**

- The dispatcher's `/implement-mainspec` gate is `./prds/<f>/run-prd-test.sh` exit code.
- The runner is committed to the branch; modifying it requires a PR.
- The non-bypassable layers (pre-commit, CI, slice signals, PRD runner) are enforced by git/CI infrastructure independent of the agent's decisions.

### Invariant 9 — Forward-only state machine

**Statement.** Skills walk forward only. No skill un-touches a sentinel. Recovery from a wrong plan is human-triggered (refile the PRD), not dispatcher-rewound.

**Why it matters.** A state machine that can rewind has more states and more failure modes. The no-rewind rule keeps the system shape small enough to reason about.

**What breaks if violated.** A skill that deletes another skill's sentinel introduces hidden coupling — now skill B depends on skill A's behavior in ways the if/elif doesn't show.

**How it's enforced.**

- `/spec-validate` patches spec files in place and writes its sentinel; it does not un-touch `.planning-done`.
- Recovery from a fundamentally wrong plan = human deletes the feature branch and refiles the PRD.

**Trade explicit.** `/implement-mainspec` is now the only "is the plan actually right?" check, since validate can no longer reject a plan and loop back to planning. The PRD runner exit code is what catches a wrong-plan implementation. See § 4 — Live trade-offs.

---

## § 3 — Local vs server side-by-side

The invariants above are stated mode-independently. The OS-level enforcement mechanism varies; the property does not.

| Invariant | Local enforcement | Server enforcement | Notes |
|---|---|---|---|
| 1 — State on disk | harness repo `state/<env>/` + committed sentinels | Same, on the runner's checkout | Identical |
| 2 — Branch as registry | Atomic git ref ops on origin | Same | Same primitive; lower contention server-side |
| 3 — Worktree ↔ branch 1:1 | `git worktree add` + HEAD guard | Each runner job = fresh checkout; implicit 1:1 | Server gets it "for free" via job ephemerality |
| 4 — Skill idempotency | Write-then-touch in skill code | Same | Identical |
| 5 — Dispatcher discipline | Pure bash + per-env `flock -n` + exit-code protocol | GH Actions workflow + `concurrency:` key per branch | `flock` and `concurrency:` serve the same role |
| 6 — Developer sandbox | Ref-only ops on the clone + sibling worktrees | N/A — no developer checkout on server | Becomes trivial server-side; remains stated for portability |
| 7 — Cross-node safety | Atomic ops + ls-remote checks | Same; usually N=1 on server | Same primitives, lower contention |
| 8 — Verification non-bypass | Dispatcher invokes runner | Workflow step invokes runner | Identical |
| 9 — Forward-only state | Skills don't un-touch | Same | Identical |

A few mode-specific notes worth carrying with you:

- **`/intent` always runs locally.** It's conversational; needs a human at a terminal. Server picks up after the `prd/<f>` branch is pushed. Universal, not a mode difference.
- **Counter location.** Per-harness `state/<env>/` files. On server (N=1) this is effectively per-branch since one server owns each branch's lifetime. On local with multi-node handoff, counters reset on the new machine — see § 4.
- **`flock` ↔ `concurrency:`.** Same role: serialize ticks against the same work unit.
- **Wipe at tick start ↔ fresh checkout per run.** Same semantics; uncommitted state has zero lifetime across runs in either mode.
- **Cross-node primitives cost nothing when N=1.** Leave them in regardless of mode — they're the upgrade path.

---

## § 4 — Live trade-offs (what's a choice, not a law)

Five decisions in the design are choices, not invariants. Each can be flipped per project.

### Steps per tick — one per branch (chosen) vs many

**Alternative.** Chain steps within a tick (e.g., if `/spec-planning` finishes, immediately invoke `/spec-validate` in the same tick).

**Why one was chosen.** Observability. A human reading disk state should be able to predict the next action without simulating the dispatcher's runtime.

**When to flip.** Wall-clock latency on multi-step features is unacceptable and you've genuinely outgrown single-step. Most projects haven't.

### Completion signal — sentinel files (chosen) vs git-derived state

**Alternative.** Derive completion from queries like `git rev-list HEAD -- specs/<f>/mainspec.md`.

**Why sentinels.** They say "this phase is complete" rather than "some file exists." Cleaner contract, simpler to check.

**When to flip.** You want zero sentinel-file noise in the repo and are willing to write more complex state derivation. Rarely worth it.

### Default concurrency — `MAX_WORKTREES=1` (chosen) vs higher

**Alternative.** Default 2 or 3 to enable parallelism out of the box.

**Why 1.** Single-developer simplicity. One feature at a time, no disk multiplication, no rebuild duplication. Devs who want parallelism flip one env var.

**When to flip.** Team projects with multiple concurrent features and surplus disk + CI capacity.

### Counter location — per-harness `state/<env>/` (chosen) vs per-branch committed

**Alternative.** Counters committed to the feature branch itself (one commit per round).

**Why per-harness.** Works for both pure-local single-dev and pure-server N=1. The handoff case (laptop dies mid-PR-debate, resume on desktop) is the only place per-node hurts, and the failure mode is "extra LLM rounds," not "wrong behavior."

**When to flip.** Shared-pool concurrency (multiple harnesses cooperating on the same branch) or scenarios where machine handoff is common and the cost of extra rounds matters.

### `feature/*` ownership contract — PRD-file-committed (chosen) vs loose match

**Alternative (loose).** Pick up any `feature/*` on origin.
**Alternative (local file).** Record claims in a local state file.

**Why PRD-file-committed.** Stateless, cross-node-safe, no per-node tracking. Also gives a clean opt-in mechanism for non-`/intent` work — commit a PRD stub on a branch and the harness picks it up.

**When to flip.** Never expected. The loose match was the pre-refactor behavior and led to the script picking up stray branches.

---

## § 5 — Failure-mode walkthroughs

Each walkthrough names the failure, traces what happens tick by tick, and points to the invariants that compose the recovery.

### Skill crashes mid-execution

**Setup.** `/spec-planning` is running on `feature/foo`, has committed `mainspec.md`, then segfaults before writing `.planning-done`.

**Tick N+1.**

1. Flock acquired (Invariant 5).
2. Re-attach step: `feature/foo`'s worktree still exists, has PRD; counted as in-flight.
3. Advance loop iterates `feature/foo`. Worktree HEAD matches (Invariant 3). Wipe runs (Invariant 1).
4. if/elif: `.planning-done` absent → re-invoke `/spec-planning`.
5. `/spec-planning` re-runs idempotently (Invariant 4), eventually writes sentinel.

**Invariants composed.** 1, 4, 5.

### Dispatcher killed by `kill -9`

**Setup.** Tick mid-execution; `kill -9` on the dispatcher process.

**Tick N+1.**

1. Flock auto-released when previous process died (file descriptor cleanup).
2. Re-attach: any worktrees that existed still exist.
3. Re-derive state from disk; resume.

**Invariants composed.** 1, 5.

### Two ticks fire concurrently

**Setup.** The `context-specs start` supervisor fires a tick at the same moment a human runs `context-specs run` by hand for the same environment.

**Trace.**

1. Tick A acquires the per-env `flock` on `state/<env>/tick.lock` first.
2. Tick B's `flock -n` fails; script exits 0 (idle).
3. Tick A proceeds normally. (A tick for a *different* environment holds a
   different lock file and is unaffected — environments never serialize
   against each other.)

**Invariants composed.** 5.

### Two harnesses race on the same PRD

**Setup.** Alice runs `context-specs start` on her laptop and forgot a running supervisor on her desktop. Both see `prd/alice/foo`.

**Trace.**

1. Both reach the claim step.
2. Laptop pushes `origin/prd/alice/foo:refs/heads/feature/foo` first; succeeds.
3. Desktop's push fails non-fast-forward (origin no longer has `prd/alice/foo`); exits cleanly.
4. Laptop creates worktree, starts work.
5. Desktop's advance loop sees `feature/foo` but no local worktree; skips (no work to advance).

**Invariants composed.** 2, 3, 7.

### Two harnesses fire on the same merge sha

**Setup.** A feature merges to main; Alice's laptop and a CI server both observe the merge within the same debounce window.

**Trace.**

1. Both call `git ls-remote origin learn/<sha>`.
2. Whichever creates `learn/<sha>` first wins; the other sees it exists and exits.

**Invariants composed.** 2, 7.

### `MAX_WORKTREES` lowered while features are in-flight

**Setup.** Harness was running `MAX_WORKTREES=3` with three features in flight; user restarts with `MAX_WORKTREES=1`.

**Tick N+1.**

1. Re-attach iterates all three `feature/*` with PRDs; re-attaches all three worktrees. `in_flight=3`.
2. Claim step: `capacity = 1 - 3 = -2`. Conditional `(( capacity > 0 ))` fails; no new claims.
3. Advance loop iterates all three; all advance one step.

**Result.** In-flight work continues regardless of the lowered cap; new PRDs queue in `prd/<slug>/*`. The cap throttles intake, not continuation.

**Invariants composed.** 1, 3.

### Human laptop dies mid-PR-review

**Setup.** Alice's laptop is at `feedback-rounds-foo=3` (two away from STUCK cap of 5). Laptop is bricked. Alice clones her harness repo and the project fresh on her desktop, runs `context-specs add` + `start`.

**Tick fires on desktop.**

1. Re-attach: `feature/foo` exists, has PRD, no local worktree — `git worktree add` creates it.
2. Advance: `state/<env>/feedback-rounds-foo` doesn't exist on the new machine; effective counter is 0.
3. If a reviewer finding is unresolved, `/address-feedback` is invoked with counter incremented to 1 (not 4).

**Result.** Alice gets the full 5 rounds again; extra LLM rounds, never broken correctness. This is the per-node counter limitation called out in § 4. Mitigation if it matters: commit counters to the branch (per-branch alternative).

**Invariants composed.** 1, § 4 (counter location trade-off).

---

## See also

- [Documentation overview](../overview.md) — the narrative these properties underpin, starting from context engineering.
- [The dispatcher](../concepts/the-dispatcher.md) — the intuition for why the harness is safe; this document is its proof.
- [`scripts/poll-and-dispatch.sh`](../../scripts/poll-and-dispatch.sh) — the dispatcher: the canonical realization of these invariants in code.
