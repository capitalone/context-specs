---
name: fix-local-checks
description: Patch the code so `scripts/local-checks.sh` passes, after /implement-mainspec — a narrow post-implement polish specialist. Reads the (remediation-rich) check failures, fixes the underlying cause, never silences a check, re-verifies, and commits. Invoked headless by the dispatcher's two-strike local-checks gate; the dispatcher owns the retry counter. Triggers - fix-local-checks, fix lint, fix local checks, fix typecheck, make checks pass, post-implement polish (project)
---

# fix-local-checks

A **narrow specialist**, not a second `/implement-mainspec`. The feature already
works — `./prds/<f>/run-prd-test.sh` exits 0 by the time you run. Your only job is
to make the project's deterministic gate, `scripts/local-checks.sh`, pass **by
fixing the underlying cause** the failing checks point at. One focused pass, then
commit and exit.

You run **headless**, invoked by the dispatcher as `/fix-local-checks <feature>`
inside the feature worktree, after a deterministic auto-fix pass (`local-checks.sh
fix`) already ran and the gate is still red.

## The one thing that matters: fix the cause, never silence the check

A check passing is a **proxy** for the code being right, not proof of it. You can
almost always turn a red check green the cheap way — suppress it, weaken it, or
delete what it was guarding. **Every one of those is forbidden.** Your fix is only
real if the check passes *because the underlying problem is gone*.

This is the whole reason you exist as a separate, constrained skill: the failing
lint's error message is a **remediation prompt** — it tells you not just *what* is
wrong but *how* to fix it. Follow the fix it describes; don't make the matcher stop
matching.

## How to run this skill

### 1. Read the failures (single source of truth)
Run `./scripts/local-checks.sh` yourself and read its full output. The messages
carry the remediation hints — that's your task list. Don't rely on anything passed
in; re-derive state from the script.

### 2. Triage each failure
- **Clear-mechanical** — the fix is unambiguous and the message says how (a missing
  type/property, an import, a formatting residue, an obvious lint fix). Make it.
- **Needs-judgment** — the honest fix would change behavior, or the failure reveals
  the *plan or spec* is wrong (e.g. a layer-direction lint firing because the design
  put code in the wrong place). Do the best **honest** fix you can. If you can't fix
  it without guessing or cheating, **stop** — see step 5.

### 3. Fix the cause
Edit the source so the real problem is gone. Scope yourself to exactly what the
failing checks require — **no refactors, no new features, no cleanup of unrelated
code.** This is polish, not implementation.

### 4. Re-verify before you commit
Re-run `./scripts/local-checks.sh`. Commit **only** work that is honestly green, or
honest partial progress toward green (so attempts compound across ticks rather than
resetting). Use a descriptive message, e.g. `fix(local-checks): trim query
whitespace`. Push. The dispatcher re-runs the gate next tick to confirm.

### 5. When you can't honestly fix it
Make whatever honest partial progress you can, commit it, and exit. **Do not cheat
to force a green.** The dispatcher's counter will eventually reach `LOCAL_CHECKS_CAP`
and hand the feature to a human via STUCK — which is the **correct** outcome for a
failure you can't honestly resolve. The human gets the failing output and the
diagnosis-first checklist; their job is to find the context defect first.

## You may NEVER silence a check

These all make a check pass without fixing anything. They are off-limits, full stop:

- **Suppression directives** — `eslint-disable*`, `@ts-ignore` / `@ts-expect-error`,
  `# type: ignore`, `as`/`!` casts to quiet the type checker, `void`-ing a promise to
  quiet a floating-promise rule, `#[allow(...)]`, `//nolint`, `# noqa`.
- **Weakening the machinery** — editing lint configs, `tsconfig` strictness,
  `scripts/local-checks.sh`, or anything under `scripts/lints/`. The rules are not
  yours to relax; only a human may, deliberately, on the branch.
- **Gaming tests** — deleting tests or assertions, or mocking the unit under test so
  the test passes while asserting nothing.

### The skip rule (load-bearing)
**You may never add a test-skip marker** — `.skip`, `.only`, `xfail`,
`@pytest.mark.skip`, `it.only`, `describe.skip`, or equivalents. Sometimes the
genuinely correct resolution *is* to skip a test (it's flaky, obsolete, or blocked on
an upstream bug) — but **that is not your call to make.** The harness can't tell a
legitimate skip from a dodge, so the rule is absolute: do the honest fix you can and
let the gate reach STUCK. A **human** may add a skip while resolving the STUCK on the
branch; `/learn` then observes it in the merged diff as a deliberate, blessed
decision. The ability to skip is the human's, never yours.

## Contract with the dispatcher
- **Invoked by:** `claude -p "/fix-local-checks <feature>"`, run from inside the
  feature worktree (the dispatcher `cd`s into it; there is no print-mode `--cwd`
  flag), after the auto-fix pass left the gate red.
- **You do NOT track rounds.** The dispatcher owns the counter
  (`<harness-repo>/state/<env>/local-check-attempts-<f>`) and decides when to STUCK. You do one focused
  pass per invocation.
- **Completion:** your commit + push. The dispatcher re-runs `local-checks.sh` next
  tick; if green it moves to PR, if red it re-invokes you (or STUCKs at cap).
- **Idempotent:** safe to re-run on the same disk state — re-derive failures, fix,
  commit.

## Hard nevers
- **Never silence a check** to go green (the lists above). Fix the cause or let it STUCK.
- **Never add a test-skip marker.** The skip rule is the human's call at STUCK.
- **Never touch the check machinery** — configs, `tsconfig` strictness,
  `local-checks.sh`, `scripts/lints/*`.
- **Never refactor or add features.** Touch only what the failing checks require.
- **Never commit a fake green.** A check that passes because you suppressed it is a
  regression dressed as a fix — and `/learn` would learn it as ground truth.
