# local-checks.sh — what it proves, and how to design it

`scripts/local-checks.sh` is the project's **deterministic gate** — the dispatcher
runs it after `/implement-mainspec` and before opening a PR (two-strike retry:
`local-checks.sh fix` → `/fix-local-checks` → STUCK at the cap). This file is the
decisioning layer: *what belongs in the gate and what doesn't.* `project-discovery.md`
is the detection layer (how to read the repo for commands and surface); read both
before Step 5, and narrate the **why** to the user — they own this script and will
tune it.

## What this gate is for (and what it is NOT)

**Cheapest layer wins.** Downstream is slow and expensive — the PR reviewer costs
real money per round, CI costs a round-trip, a post-merge revert costs a follow-up
PR. Upstream is cheap and fast — a failing check here is silent token self-correction
before any of that fires. So anything deterministically catchable belongs *here*,
left of the reviewer and CI.

**Division of labor.** This gate is the **computational floor** — deterministic,
fast, runs every time. The reviewer is the **inferential layer** — it spends model
tokens on semantic/logic review. Don't make the reviewer do lint's job (it'll flag
nits as noise, or miss them), and don't make this gate attempt semantic review. Push
everything mechanizable down to the floor so the inferential layer spends its tokens
on what only it can do.

**It proves correctness, not coverage.** Only add a check that proves something is
*right* or prevents a known *bug-class*. Do not add checks that chase a metric or
enforce taste. More checks is not better; the *right* checks are better.

## Responsibility A — wire the project's deterministic checks

Detect the project's actual commands (`project-discovery.md`) and generate a script
that runs them. Prefer the command the project already defines (its
`package.json`/`Makefile` scripts) over a generic one — it carries the project's
flags. If the project already has pre-commit hooks, **call them, don't duplicate**.

Include, in roughly fastest-to-slowest order:

- **Lint / format** — with a `fix` subcommand (`./scripts/local-checks.sh fix`) for
  the auto-fixable ones. The dispatcher's attempt-0 calls `fix` before any agent runs.
- **Typecheck** — block. A type error is a correctness failure.
- **Fast unit tests** — block. This is the *shifted-left* copy of CI's test run; its
  unique value is catching **cross-slice regressions** (slice signals only run
  per-slice, so a later slice breaking an earlier slice's test won't surface until
  CI otherwise). Keep it to the **fast** suite — slow/integration/e2e stays in CI.
- **Skip-detection** — block. See "The skip rule" below.
- **Everything in `scripts/lints/`** — the directory `/learn` grows custom invariant
  lints into over time. Have the script run them all.

**Mutation testing does NOT belong here.** It's the only true "are the tests
discriminating?" proof, but it's far too slow for this hot-path gate. If the project
wants it, it runs as an async/nightly sensor, never as a blocking local check.

## Responsibility B — propose custom correctness lints (snapshot discovery)

At init there's no merge history, but the **existing codebase is evidence**: a
pattern the code already upholds universally is an observed invariant you can lock
in today. So you may **propose** candidate lints from two sources:

- **(a) Observed existing invariants** — patterns the code already follows everywhere
  (e.g. nothing under `repo/` imports from `service/`). Strongest, because evidenced.
- **(b) Project-type best-practice correctness lints** — for light/greenfield repos,
  suggest from best practice, but **scoped to the project's actual detected surface**:
  a Prisma schema → "no raw SQL interpolation" is relevant; an external-input boundary
  → "parse at the boundary." No DB → don't suggest a SQL lint.

Five guards keep this from becoming volume-by-checklist. **Propose; the user disposes.**

1. **`must-pass-current-main` is the discriminator (free here).** Draft the candidate,
   run it against the current code. A real universal invariant passes clean; an
   incidental or aspirational one reddens existing files — which is your signal it
   isn't actually an invariant.
2. **Never auto-grandfather.** If a pattern holds in 95% of files and 5% violate it,
   that's a migration, not an enforceable invariant. Surface the violators ("clean
   these first, or this isn't lintable yet"); never silently baseline them.
3. **Block only correctness/structural.** Layer-direction, parse-at-boundary, no SQL
   injection, no unsafe casts → block. Legibility (grep-ability, naming) and
   observability (logging shape) are **warn**, not block, even when the pattern is
   real. Don't hand-author a custom lint for what the project's own linter already does.
4. **Scope to the actual surface, not a generic list.** Use what discovery found;
   don't ship "40 lints every Next.js app should have."
5. **Propose, never apply.** Present each candidate with its *why* and its
   must-pass-main result; the user opts in per-lint.

This is **snapshot** discovery (the code as-is, one time). `/learn` does **stream**
discovery (invariants surfacing across merges) with its own discipline. Same
principles, different evidence — and they live in separate skills; this file does
not depend on `/learn`'s.

## The correctness filter, at a glance

| Mode | What | Examples |
|---|---|---|
| **Block** | Correctness / structural | Lint errors, typecheck, fast tests, skip-detection, layer-direction, parse-at-boundary, no SQLi/unsafe-cast |
| **Warn** | Legibility / observability (real but not present-tense bugs) | Grep-ability, naming conventions, log shape |
| **Sensor (not here)** | Test fitness | Mutation testing — async/nightly only |

## How to write a good lint

A lint is only as valuable as the message it prints on failure — that message is the
*prompt* a cold `/fix-local-checks` agent acts on (it has no other context). Three
things make a lint pull its weight.

**1. The message template.** Fill these in plain language:

- **WHERE** — file:line, or the offending pattern for a whole-repo/graph rule.
- **WHAT** — the violation as a fact about *this* code, not the rule in the abstract.
- **WHY** — one clause. Without it the agent satisfies the letter and breaks the intent.
- **FIX** — the concrete change to make (a short menu if several fixes are valid).
- **DON'T-CHEAT** — name the silencing trap for this rule.

Bad: `error: layering violation in repo/user.ts`. Good:

```
❌ repo/user.ts:12 imports from service/ (layer direction Types→Repo→Service→UI).
   WHY: layers compile bottom-up; a repo→service edge breaks build order.
   FIX: move the shared type to types/, or invert via a Provider interface.
   Don't silence with a path alias — that hides the same edge.
```

**2. Decide the fix path** — it maps onto the dispatcher's two-strike gate:

- **Autofixable + safe** (unique, semantics-preserving) → wire into
  `local-checks.sh fix`; the agent never spends a token on it.
- **Needs judgment** (several valid fixes, or the choice is semantic) → no autofix;
  the message must carry enough for `/fix-local-checks` to choose well.
- **Detect-only** (no mechanical fix) → still ship it; expect `/fix-local-checks`,
  or STUCK.

**3. Make it discriminating (match-as-proxy).** The lint's match is a *proxy* for the
problem, not the problem itself. Design it so the cheap way to satisfy it is also the
*right* way; if deletion or suppression would satisfy it, it's gameable — add a
companion guard (skip-detection is exactly this: it guards test *removal*, which a
plain "tests pass" check would reward).

## The skip rule (load-bearing)

A skip-detection check fails if the diff **adds** a test-skip marker (`.skip`,
`.only`, `xfail`, `it.only`, `describe.skip`, `@pytest.mark.skip`, …) or deletes
assertions. Reason: "all tests pass" is gameable — a skipped test is *green*.

Sometimes the genuinely correct resolution **is** to skip (flaky, obsolete, upstream
bug). But the harness can't mechanically tell a legitimate skip from a dodge, so the
rule is absolute: **an agent may never add a skip marker.** A blocked-but-legitimate
skip routes to the human via STUCK, who decides on the branch; `/learn` then sees the
human's skip in the merged diff as a deliberate, blessed decision. The ability to
skip is *relocated* to the human, not removed.

**No flaky-test allowlist.** An allowlist is editable config an agent could pad to
dodge — exactly the silencing surface we're avoiding. Every agent-added skip → STUCK.
If false STUCKs from flaky tests get noisy, that's a project-health signal worth
seeing, not suppressing.

## Contracts the generated script must honor

- `./scripts/local-checks.sh` (no arg) = **check** (exit 0 = pass). `./scripts/local-checks.sh fix` = **autofix** the auto-fixable subset.
- It runs **everything in `scripts/lints/`**, so `/learn`'s future lints are picked up with no rewiring.
- **Custom lints must emit remediation-aware messages** — the error is a *prompt*:
  say not just *what* failed but *how* to fix it. `/fix-local-checks` reads these
  cold (fresh context); a terse "rule violated" leaves it guessing. Name the
  silencing trap in the message too ("don't `@ts-ignore` this — handle the null").

## What NOT to do

- **No dedicated anti-cheat lint.** We deliberately do *not* ship a `no-suppressions`
  check. The agent-side guard against silencing lives in the `/fix-local-checks`
  prompt; the human (merge) and reviewer are the backstops. Keep the silencing-trap
  warning in each lint's own message instead.
- **Don't chase volume.** Coverage, legibility, and style as *blocking* gates are the
  anti-pattern. Correctness blocks; the rest warns or doesn't ship.

## Dependency: a runnable worktree

Because the gate runs typecheck and tests, the harness worktree must be **fully
runnable** — deps installed, codegen run — or these legs fail for the *wrong reason*
(spurious red → wasted attempts → false STUCK). This raises the bar on
`scripts/bootstrap-worktree.sh` (Step 6): if discovery there is thin, ask the user
how they provision a fresh checkout. A correct local-checks gate depends on a correct
bootstrap.
