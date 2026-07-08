# The eval contract

An eval is the load-bearing artifact of continuous improvement: it freezes *"given this
context, the harness should behave like this"* so a future context change can't silently
regress it — and so a context edit's value is **measurable** instead of vibes. This is
the observe-a-trace → capture-an-eval → fix-the-context → it-persists flywheel, where the
"prompt" being tuned is the project's own context.

> Governing principle: **an eval tests the harness's own skills/context, not the product.**
> A PRD runner (`prds/<f>/run-prd-test.sh`) asks "does the *feature* work?". An eval asks
> "given this context, does the *harness* behave as it should?". Different question,
> different home — keep them separate so neither rots the other.

**Why this is exciting (tell the human).** Authoring an eval is the moment their *own
project* becomes an agent harness they can evaluate and improve: each eval is a graded
trial of the project's context that compounds — the project gets better at building
itself over time.

## Where evals live — in the project, in two families

Evals live in the **dev's project**, under `evals/` at the repo root — a runtime artifact
of the project, like `prds/` and `specs/`. Human-in-the-loop, run from the user's own
checkout. (A long-term-memory case does spin one *disposable* worktree to re-plan against a
historical commit — an internal mechanic of `plan-in-isolation.sh`, torn down after; never
one of the harness's managed per-feature worktrees.)

```
<project-repo>/evals/
├── README.md                        # the contract, for humans who find the dir cold
├── run-all.sh                       # aggregator: runs every case's run-eval.sh
├── long-term-memory/
│   └── <case>/
│       ├── fixture/                 # feature slug + (A) pre-plan sha + (B) old-plan sha
│       ├── judge.md                 # the co-authored rubric (hackable seam)
│       └── run-eval.sh              # new-vs-old attribution report; exit 0 iff Expert didn't hurt
└── lints/
    └── <lint-name>/
        ├── fixture/                 # a mocked violation of the lint
        ├── judge.md
        └── run-eval.sh
```

Case names are behavior slugs (`spec-planning-honors-ssr-constraint`), not feature names.
A legacy flat `evals/<name>/` case still runs via `run-all.sh`'s glob; offer to move it
under the right family when you touch it.

### Scaffolding `evals/` on first use

If the project has no `evals/` dir yet, create it with the first eval — a `README.md` and
`run-all.sh`, committed on the same branch as the eval.

`evals/README.md` (project-facing — adapt the wording):

```markdown
# `evals/` — regression tests over this project's harness context

Authored with `/improve-context` when a build trail, a STUCK, or a context edit reveals
something worth freezing. Two families: `long-term-memory/` (does the Expert improve
spec plans?) and `lints/` (is each lint's error message a sufficient fix-prompt?).
Evals test the **harness** ("given this context, does it behave?");
`prds/<f>/run-prd-test.sh` tests the **product** ("does the feature work?"). Keep them
separate.

Contract: one dir per case — `<family>/<case>/{fixture/, judge.md, run-eval.sh}`.
`run-eval.sh` exits 0 iff the expected behavior holds. A new eval's verdict must MOVE with
the context it tests — a long-term-memory case: the Expert edit changes the plan for the
better; a lint case: red before the message fix, green after.
```

`evals/run-all.sh`:

```bash
#!/usr/bin/env bash
# Run every eval case (both families, plus any legacy flat cases). Exit 0 iff all pass.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
fail=0 ran=0
for runner in "$here"/*/run-eval.sh "$here"/*/*/run-eval.sh; do
  [[ -e "$runner" ]] || continue
  ran=$((ran + 1)); name="${runner#"$here"/}"; name="${name%/run-eval.sh}"
  if bash "$runner"; then echo "PASS  $name"; else echo "FAIL  $name"; fail=1; fi
done
(( ran == 0 )) && echo "no evals yet (evals/<family>/<case>/run-eval.sh)"
exit $fail
```

## The runner contract (mirrors the PRD runner deliberately)

`run-eval.sh` borrows `run-prd-test.sh`'s shape exactly, so the project has *one* mental
model for "runnable definition of correct":

- **Exit 0 = the expected behavior holds; non-zero = it doesn't.** That's the whole API.
- **Internals are free** — deterministic checks, a `claude -p` judge, or a mix.
- **Self-contained under the case dir.** Fixtures, judge prompt, helpers all live beside
  the runner, sandboxed from the project's own test discovery.

---

# Family 1 — `evals/long-term-memory/`: did the Expert change the plan, for the better?

**What's judged: the plan, never a re-implementation.** Long-term memory (the Expert)
informs short-term memory (spec planning → mainspec + slices). The plan is the Expert's
direct causal output, so the plan is what gets graded — re-running implementation would
add cost, nondeterminism, and two confounders (the implementer, the environment) between
the thing being changed and the thing being measured. Production already grades the outer
loop (attempt counters, STUCK rate).

**The comparison is temporal: today's plan vs. the plan that actually shipped.** For a
merged feature, git already holds the spec plan generated back *then*. We re-run
spec-planning *now* — against that feature's pre-plan checkout, with **today's Expert** —
and compare the new plan against the historical one. The developer's real question, *did
the Expert edits I just made change the plan, and for the better?*, is answered by that
before/after — not by a synthetic with-Expert-vs-without ablation. The old plan is the real
baseline the harness produced; nothing to fabricate.

## The three shas a case needs (all already in git history)

A long-term-memory case is built from **one merged feature**, and everything it needs
already exists — no gold to curate, no synthetic baseline to generate:

- **(A) pre-plan sha** — the commit where `prds/<f>/{prd.md,run-prd-test.sh}` exist but
  `specs/<f>/` does not. This is the code we re-plan against: the implementation isn't
  present to be "discovered", and the PRD is present as the planning input.
- **(B) old-plan sha** — the commit that first added `specs/<f>/mainspec.md` (+ slices).
  This *is* the baseline plan — the one the harness produced back then. No regeneration.
- **(C) code diff** — `A..tip` excluding `prds/` and `specs/`: what actually shipped. Not
  judged directly; it's the ground truth you build the rubric from (see the rubric below).

`scripts/harvest-eval-inputs.sh` prints all three per merged feature. **Confirm they exist**
for your chosen feature before building the case; if a feature's `/intent` and
`/spec-planning` landed in one squashed commit (no clean (A)/(B)), pick another feature that
has them. This family is **regression-only**: a not-yet-built feature has no (B) plan and no
(C) diff, so it can't be a case yet — build it after the feature ships.

## Setup — inspect the harness, don't hardcode the invocation

Re-running spec-planning headless has exactly two traps, and both are why you **inspect the
harness this environment runs under** instead of assuming `claude -p` flags:

1. The harness's tier-1 skills (incl. `spec-planning`) reach a project as **gitignored
   symlinks** in `.claude/skills/`. A plain `git clone` / `git worktree add` does *not*
   carry them, so `claude -p "/spec-planning …"` answers **"Unknown command."** The fresh
   checkout must be re-linked — `context-specs link <wt>`, or the project's
   `scripts/bootstrap-worktree.sh` (its deterministic header does the same link).
2. The right permission posture is the **harness's**, read the way the dispatcher reads it:
   default `--permission-mode auto`, overridable per-environment in `.harness/env`. Never
   hardcode `--dangerously-skip-permissions` / `bypassPermissions` — read the effective
   value (`CLAUDE_PERM_ARGS`) from the environment.

The shared helper **`scripts/plan-in-isolation.sh`** does all of this correctly — **read it
before writing a case**; it is the reference for how this project invokes planning. Given a
feature + the (A) sha it: spins a *disposable* worktree at (A) (not a harness-managed one),
overlays today's Expert, links the skills, invokes `/spec-planning <feature>` the harness's
way, captures `specs/<f>/` off disk, and deletes the worktree — whatever planning committed
dies with it, so **no real branch is touched**. A case's `run-eval.sh` stays short: call the
helper for the new plan, `git show <B-sha>:specs/<f>/mainspec.md` (and its slices) for the
old plan, then judge.

> **Run these from a human shell.** The helper launches an autonomous, file-writing
> `claude -p`; an agent in auto mode is blocked from spawning it. Long-term-memory cases are
> human-invoked (minutes + real tokens) and are **not** part of `scripts/local-checks.sh`.

## The output that matters — the attribution report

The eval's primary artifact is **not** a bare PASS/FAIL. It's a report that shows the
developer *what their Expert edits did*:

1. **Plan diff** — old (B) → new, human-readable: what the new plan says that the old one
   didn't, and vice-versa.
2. **Attribution** — each *substantive* difference tied to the Expert shard that **likely**
   produced it ("the new plan scopes the trailing window as timezone-safe — traceable to
   `invariant-timezone-safe-dates`"). Differences that map to **no** shard are labeled
   **drift** (model / skill / nondeterminism), not Expert impact. Attribution is a
   *hypothesis*, never proof — say "likely"; let the drift bucket absorb what memory can't
   explain. That bucket is the load-bearing guard against the confound below.
3. **Rubric verdict** — judge the new plan against the old on the co-authored rubric
   (below), **blind** (label the two A/B, order shuffled), then reveal which is new. A
   one-line net read sits on top: the Expert edits **helped / were neutral / hurt** — and
   *hurt ⇒ the eval fails* (an edit made the plan worse).

**The confound to name out loud.** The old plan was generated *then* (older model, older
spec-planning); the new plan *now*. So "the new plan is better" is not automatically "your
Expert helped." The attribution step is the safeguard: only **shard-traceable** improvements
count as Expert wins; a better-but-unattributable plan is drift. Also surface **what Expert
the baseline had**: a feature that shipped *before* the Expert was seeded shows the whole
Expert's value in one shot; one that shipped *with* a rich Expert shows only your
*incremental* edits. Show the baseline's Expert state so the verdict can be read honestly.

## The rubric (`judge.md` — co-authored, approved before any run)

**The rubric is the work, and it is the developer's.** Do not draft it alone and present it
— build it *with* them, iterate, and get explicit sign-off *before* running. Seed it from
ground truth you put in front of them: the **PRD + runner** (the why/what) and the **code
diff (C)** (what a passing, quality implementation actually looked like). Walk the diff with
them; say plainly "the implementation looks good," or surface the *non-nitpick* things that
could have been better — those become criteria that reward a plan for steering around them.

The spine is three criteria (add project-/feature-specific ones live, with the human):

1. **Sufficiency for correctness** — would an implementer following this plan plausibly
   reach an implementation that passes `run-prd-test.sh`? (Grounded in the runner + diff.)
2. **Sufficiency for quality** — does the plan steer toward the bar the shipped code met:
   reusing what exists, honoring the project's rules (the `invariant-*` / `pattern-*` shards
   in scope), not reinventing? (Grounded in the diff + the Expert.)
3. **What could've been better** — the per-case criteria seeded by the diff walk above. This
   is where "the shipped impl was itself suboptimal, so reward a plan that diverges" lives —
   folded into the rubric conversation instead of a separate `gold.md`.

Judge each criterion as a **comparison** (new better / old better / tie), with a citation:
the plan text plus the shard or diff evidence. No absolute scores, no passing on vibes.
Deliberately **excluded**: plan-structure polish (slice sizing, ordering) — that measures
`/spec-planning`, not the Expert.

**Every run is also a backlog.** The judge ends with *"what should the Expert have contained
that would have improved the weaker plan?"* — each candidate pointing at something the diff
shows a good plan needs but the plan missed. The human curates: write the shard only if it
generalizes beyond this one case, re-run, watch the verdict move.

## Suite discipline

Small and curated — 3–5 cases spanning work types (a product feature, a refactor, a
bugfix) — grown from real features: when a STUCK diagnosis or a build audit lands on
"Expert gap," freeze that feature as a case. Don't chase volume; every case is a vector
that shifts behavior.

**Rubric validity is checked against the outer loop.** The harness's production attempt
counters and STUCK rate are the ground truth: if eval verdicts trend "Expert helped" over
time but implement attempts don't fall, the rubric is measuring the wrong thing — fix
`judge.md`, not the suite.

---

# Family 2 — `evals/lints/`: is the error message a sufficient prompt?

A lint's failure message is the *prompt* a cold `/fix-local-checks` agent acts on — it
has no other context. This family tests exactly that property:

1. **Fixture:** a minimal mocked violation of the lint (a file or small tree under
   `fixture/` that the lint should flag).
2. **Run the lint** against the fixture; capture its failure message.
3. **Feed ONLY the message** (plus the fixture) to a cold `claude -p` — no Expert, no
   AGENTS.md, no conversation: exactly what `/fix-local-checks` gets.
4. **Judge:** did the agent correctly diagnose the violation and produce the right fix
   from the message alone — without silencing (`judge.md` names the silencing trap for
   this rule)?

A FAIL here means the message needs WHERE / WHAT / WHY / FIX / DON'T-CHEAT work (see
`env-init/references/local-checks-design.md`), not that the lint's rule is wrong.

Skeleton `run-eval.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"

msg="$(bash "$(git rev-parse --show-toplevel)/scripts/lints/<lint>.sh" "$here/fixture" 2>&1)" && {
  echo "fixture did not trip the lint — fixture or lint is broken"; exit 1; }

fix="$(claude -p "You are fixing a failed check in an unfamiliar repo. The only
information you have is this failure message and the file(s) it names.

===== FAILURE MESSAGE =====
$msg

===== FIXTURE =====
$(cat "$here"/fixture/*)

Describe the exact change you would make, and why.")"

verdict="$(claude -p --model claude-haiku-4-5 "$(cat "$here/judge.md")

===== PROPOSED FIX =====
$fix

Answer with a single line: PASS or FAIL: <one-line reason>.")"
echo "$verdict"
grep -q '^PASS' <<<"$verdict"
```

---

# The right-reason check (both families — what separates a real eval from a fake one)

`/intent` requires a PRD runner to **fail for the right reason** before the feature
exists. An eval is the mirror:

1. **Its verdict must move when the context moves.** For a long-term-memory case: with the
   shard under test *removed* from the Expert, the new plan should collapse toward the old
   one (the attributable difference disappears); with it *in*, the difference appears and
   the verdict favors it. For a lint case: red against the misleading message, green once
   it's fixed. An eval whose verdict doesn't depend on the context it tests proves nothing —
   it reads as "covered" while covering nothing.
2. **A long-term-memory case passes on attribution, not just on winning.** The new plan
   must beat the old *and* the improvement must be **traceable to a shard**, not to drift.
   If the new plan wins but nothing ties the win to the Expert, you haven't shown memory
   helped — tighten the case or the rubric.

If you can't make a case's verdict flip by adding/removing the shard under test, you
haven't isolated the defect yet — go back to the diff and the trace.

## When NOT to write an eval

- The finding was **inherent difficulty**, not a context defect — nothing to freeze.
- The behavior is already covered — extend the existing `judge.md` instead of spawning a
  near-duplicate.
- The fix is a **lint** (mechanically checkable). The lint *is* the regression test for
  the rule — an `evals/lints/` case tests the lint's *message quality*, which is a
  different, optional question.

A clean trail, or a trail whose only finding is "this was hard," produces **no eval**.
That is a correct and common outcome.
