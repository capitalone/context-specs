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
of the project, like `prds/` and `specs/`. Human-in-the-loop, run in the user's own
checkout: no worktrees, no harness machinery.

```
<project-repo>/evals/
├── README.md                        # the contract, for humans who find the dir cold
├── run-all.sh                       # aggregator: runs every case's run-eval.sh
├── long-term-memory/
│   └── <case>/
│       ├── fixture/                 # prd.md, run-prd-test.sh, base-sha (regression cases)
│       ├── gold.md                  # human-approved reference: what a good plan does
│       ├── judge.md                 # the rubric (hackable seam)
│       └── run-eval.sh              # exits 0 iff the expected behavior holds
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

Contract: one dir per case — `<family>/<case>/{fixture/, judge.md, run-eval.sh}`
(+ `gold.md` for long-term-memory regression cases). `run-eval.sh` exits 0 iff the
expected behavior holds. A new eval must go RED against the context that misled the
agent and GREEN once it's fixed.
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

# Family 1 — `evals/long-term-memory/`: does the Expert improve plans?

**What's judged: the plan, never a re-implementation.** Long-term memory (the Expert)
informs short-term memory (spec planning → mainspec + slices). The plan is the Expert's
direct causal output, so the plan is what gets graded — re-running implementation would
add cost, nondeterminism, and two confounders (the implementer, the environment) between
the thing being changed and the thing being measured. Production already grades the outer
loop (attempt counters, STUCK rate).

## Two case modes, one lifecycle

- **Regression case (default)** — a harvested *historical* feature: real `prd.md` +
  `run-prd-test.sh`, the merge-parent sha, and a curated `gold.md`. Pins what memory must
  keep doing; sits near-passing.
- **Capability case** — a realistic *not-yet-built* PRD, run against current code. No
  history, no checkout, no contamination; starts failing (empty/thin Expert) and gives a
  hill to climb. When its feature later ships, upgrade it in place (add the merge-parent
  sha + curated gold) — it **graduates** into the regression suite.

Harvest regression inputs with `scripts/harvest-eval-inputs.sh` — it lists every merged
feature that has both PRD and runner, with its landing sha. No manual archaeology.

## The contamination rule (regression cases)

A harvested feature is already implemented on today's `main` — planning it against
current code would trivially "discover" the existing implementation and pass with an
empty Expert. So `run-eval.sh` plans against the code *as of the merge-parent*:

```bash
# Inside run-eval.sh — throwaway shared clone, gitignored, deleted after.
# This is an internal mechanic of the script (NOT a harness worktree; the user's
# tree is never touched): the committed eval definition is what lives in the repo.
workdir="$here/workdir"; rm -rf "$workdir"
git clone --shared --no-checkout "$(git rev-parse --show-toplevel)" "$workdir"
git -C "$workdir" checkout --detach "$(cat "$here/fixture/base-sha")"
# Overlay TODAY'S Expert (the thing under test) onto the historical code:
rm -rf "$workdir/.claude/skills/expert"
mkdir -p "$workdir/.claude/skills"
cp -R "$(git rev-parse --show-toplevel)/.claude/skills/expert" "$workdir/.claude/skills/expert"
```

Add `workdir/` to `evals/.gitignore` when scaffolding the first regression case.

## Pairwise ablation — "did memory help?" as a runnable question

Run `/spec-planning` headless **twice** for the fixture PRD — once with the current
Expert, once with it hidden (or with the pre-edit Expert version, when measuring one
edit) — then the judge compares the two plans **blind** (labeled A/B, order shuffled).

Pairwise is deliberate: LLM judges are unreliable at absolute scales ("score this 7/10")
and reliable at anchored comparison ("which plan is better on dimension X, and cite
why"). It answers the real question — *did memory help?* — rather than *is the plan
good?* (a plan can be good because the model is smart, with the Expert contributing
nothing). And it gives memory edits red-before / green-after: after an Expert edit, the
verdict on the affected dimension should flip.

## Curated gold — the shipped diff is evidence, not truth

For regression cases the judge also gets `gold.md` plus the real merged diff. But the
shipped implementation is **not automatically the right answer** — sometimes the Expert
is being updated precisely because hindsight showed the implementation should have been
different. So:

- At case creation, **draft** `gold.md` from the shipped diff: what the implementation
  did, what it got right, and what hindsight says should have been different. The
  **human edits and approves it** — gold is a human judgment call, LLM-drafted.
- The judge grades against `gold.md`, with the raw diff attached as evidence. Where they
  disagree, the curated notes win — the eval may deliberately *reward* plans that diverge
  from the shipped diff.
- Freezing a case right after a STUCK or a wince-inducing review is the cheap moment:
  that's when the human knows exactly what should have been different.

## The rubric (`judge.md` — the hackable seam)

Binary pass/fail per dimension — no scales — and every verdict must **cite** the Expert
shard or gold evidence that justifies it. No passing on vibes.

1. **Names & abstractions** — the plan speaks in the project's real terms and extends
   existing abstractions rather than inventing parallel ones.
2. **Patterns followed** — the `pattern-*` shards in scope are honored.
3. **Invariants addressed** — enumerate the `invariant-*` shards in scope; each is
   satisfied by the plan or explicitly handled. (Closest to mechanical; highest signal.)
4. **Reuse over reinvention** — the plan points at existing code/utilities the Expert
   documents instead of planning new ones.
5. **Verification native to the project** — slices verify the way this project verifies
   (its frameworks, `how-to-*` procedures, the PRD runner named in the final slice).

Deliberately **excluded**: plan-structure quality (slice sizing, ordering) — that
measures `/spec-planning`, not the Expert. Keep the eval's blast radius on the lever
being iterated.

**The missing-shard listing (the generative output).** The judge's report must end with:
*"what should the Expert have contained that would have improved this plan?"* — each
candidate grounded in `gold.md` (it must point at something the gold says a good plan
does that this plan missed). Candidates are proposals: the human curates, writes the
shard only if it generalizes beyond this one case, re-runs, and watches the verdict
flip. Every eval run is a grade *and* an improvement backlog.

## Suite discipline

Small and curated — 3–5 cases spanning work types (a product feature, a refactor, a
bugfix) — grown from real failures: when a STUCK diagnosis lands on "Expert gap," freeze
that feature as a case. Don't chase volume; every case is a vector that shifts behavior.

**Rubric validity is checked against the outer loop.** The harness's production attempt
counters and STUCK rate are the ground truth: if eval scores rise over time but
implement attempts don't fall, the rubric is measuring the wrong thing — fix `judge.md`,
not the suite.

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

1. **It must FAIL against the context that misled the agent.** Run it *before* the
   context fix — red, exercising the actual defect. An eval that passes trivially proves
   nothing and is worse than no eval (it reads as "covered" while covering nothing).
2. **It must PASS once the context fix is in.** Re-run after — green. Red-before,
   green-after is the proof that the eval and the fix are about the same thing.

If you can't get an eval to go red against the defect, you haven't understood the defect
yet — go back to the trace.

## When NOT to write an eval

- The finding was **inherent difficulty**, not a context defect — nothing to freeze.
- The behavior is already covered — extend the existing `judge.md` instead of spawning a
  near-duplicate.
- The fix is a **lint** (mechanically checkable). The lint *is* the regression test for
  the rule — an `evals/lints/` case tests the lint's *message quality*, which is a
  different, optional question.

A clean trail, or a trail whose only finding is "this was hard," produces **no eval**.
That is a correct and common outcome.
