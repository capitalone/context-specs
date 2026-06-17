# Verify the loop works (the planted-event dry-run)

The substrate's invariants are already proven; what's unproven in a freshly generated loop
is the **holes** — the minter, the oracle, and the phase wiring. So verification plants a
synthetic work-item and watches it travel the full pipeline, asserting the oracle goes
red→green and STUCK fires. This is `/intent`'s fail-for-the-right-reason trick, lifted to the
whole loop. Run it WITH the user as Step 8 of the skill.

## 0. Syntax sanity (free)
```
bash -n scripts/<ns>-dispatch.sh && bash -n scripts/<ns>-tick.sh
```
Catches a botched `__NS__` substitution or a broken phase edit before any real run.

## 1. Empty no-op
From the loop's infra worktree (`../<repo>-harness-ns-<ns>`), with no work-items filed:
```
./scripts/<ns>-tick.sh
```
Expected: fetch, sync to `origin/main`, find nothing, exit 0. Proves the sync wrapper +
dispatcher wiring + `harness-lib.sh` sourcing, doing no work.

## 2. Mint a synthetic item — and confirm it fails for the right reason
Run `/intent-<ns>` for a throwaway feature (e.g. a trivially checkable behavior). Confirm:
- a `<ns>/<slug>/<feature>` branch was pushed, and
- `prds/<feature>/run-prd-test.sh` exits non-zero **because the behavior is absent** — not a
  typo, missing dep, or unrelated breakage. (If it passes today, the runner tests nothing.)

## 3. Tick to green
Tick the loop repeatedly (`./scripts/<ns>-tick.sh`, or wait for the `/loop` session). Watch
the state machine advance one step per tick:
- claim → `feature/<ns>/<feature>` (the `<ns>/<slug>/<feature>` branch disappears), worktree
  created at `<repo>-harness-ns-<ns>-<feature>`;
- `/spec-planning` → `.planning-done`; `/spec-validate` → `.validated`;
- `/implement-mainspec` runs; the **oracle is red** until the behavior exists;
- once the behavior is present, the oracle goes **green → `.prd-passed` committed → PR opens**
  against `main`.
Confirm the `.prd-passed` sentinel is committed (so the judge isn't re-run every tick).

## 4. Force STUCK + confirm convergence
- **STUCK:** lower a cap in `.harness/env` (e.g. `IMPLEMENT_CAP=1`) or feed an unsatisfiable
  item; confirm the dispatcher posts the **diagnosis-first** PR comment with the session
  trail, touches `.harness/stuck-<feature>`, and halts the feature.
- **Convergence:** with a reviewer configured, confirm that posting `REVIEW_CLEAN_MARKER`
  flips the feature to HUMAN_REVIEW (the "Ready for your review" comment posts once and the
  loop halts for `/evaluate-pr`). With no reviewer (empty marker), confirm it hands off at
  PR-open.

## 5. Confirm isolation (the no-regression check)
The build loop and memory loop must be untouched:
```
git diff --stat main   # should list only NEW paths (scripts/<ns>-*, loops/<ns>/, .claude/skills/<ns>-*, .claude/skills/intent-<ns>/) + maybe .gitignore
```
And confirm the loop's worktrees use the `-ns-` infix (no collision with build-loop
per-feature worktrees).

Tear down the synthetic item afterward (close its PR; the cleanup pass removes the worktree
and counters).
