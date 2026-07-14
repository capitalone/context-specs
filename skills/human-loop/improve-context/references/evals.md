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
│       └── run-eval.sh              # prints new-vs-old attribution report (terminal + .cache); verdict is content, not the exit code
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

Contract: one dir per case — `<family>/<case>/{fixture/, judge.md, run-eval.sh}`. Each
`judge.md` opens with a one-line note on what defect or shard the case froze, so a cold
reader of the dir understands it. `run-eval.sh` prints a **report** (to the terminal and to
`<case>/.cache/last-report.md`) whose **verdict line** — `HELPED | NEUTRAL | HURT` or
`PASS | FAIL` — is the signal; the exit code only says whether the case *ran*. Read the
report and discuss it. A new eval's verdict must MOVE with the context it tests — a
long-term-memory case: the Expert edit changes the plan for the better; a lint case: the
message reads FAIL before the fix, PASS after.
```

`evals/run-all.sh`:

```bash
#!/usr/bin/env bash
# Run every eval case (both families, plus any legacy flat cases) and print each report.
# This is a RUNNABILITY smoke test, not a quality gate: a case exits non-zero only when it
# couldn't RUN (missing sha, crashed re-plan/judge). The helped/hurt verdict lives inside
# each report — read it and discuss it (see references/evals.md). Exit 0 iff every case ran.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
broke=0 ran=0
for runner in "$here"/*/run-eval.sh "$here"/*/*/run-eval.sh; do
  [[ -e "$runner" ]] || continue
  ran=$((ran + 1)); name="${runner#"$here"/}"; name="${name%/run-eval.sh}"
  echo "===== $name ====="
  if bash "$runner"; then echo "ran    $name"; else echo "BROKE  $name (couldn't run — not a verdict)"; broke=1; fi
done
(( ran == 0 )) && echo "no evals yet (evals/<family>/<case>/run-eval.sh)"
exit $broke
```

## The runner contract

`run-eval.sh` shares `run-prd-test.sh`'s *runnable-file* shape — one script under the case
dir you invoke directly — but its **signal is different on purpose.** A PRD runner's exit
code is a **binary gate the harness consumes** ("does the feature work? exit 0, or the build
stops"). An eval asks a **spectrum** question — *did this context help, hurt, or do nothing?*
— that no machine gates on and that a human and Claude **discuss.** So the eval's output
contract is a report, not an exit code:

- **Primary output = a report, printed to the terminal AND tee'd to a file.** The full
  report goes to stdout so the human sees the result the instant the run ends — never "go
  open a file." It is *also* written to a gitignored `<case>/.cache/last-report.md` so Claude
  can `Read` it directly and drive next steps — the human never copy-pastes (see *The eval
  ends in a conversation*, below).
- **The verdict lives inside the report, as content.** A machine-visible line — `VERDICT:
  HELPED | NEUTRAL | HURT` for a long-term-memory case, `PASS | FAIL: <reason>` for a lint
  case — is what Claude reads and the human reacts to. It is *not* the exit code.
- **Exit code = operational success only.** Exit 0 = the eval *ran* and produced a report;
  non-zero *only* when it couldn't run (a missing sha, a crashed re-plan or judge, a fixture
  that didn't trip the lint). A HURT verdict is a successful run with a bad result — it still
  exits 0. Nothing automated consumes this code; it exists so `run-all.sh` can flag a case
  that is *broken*, not one whose context underperformed.
- **Internals are free** — deterministic checks, a `claude -p` judge, or a mix.
- **Self-contained under the case dir.** Fixtures, judge prompt, helpers all live beside
  the runner, sandboxed from the project's own test discovery.
- **Feed a judge prompt on STDIN, never as an argv string.** An eval prompt bundles big
  inputs (a code diff, both plans, every shard) and blows past Linux's 128 KiB
  per-argument cap (`MAX_ARG_STRLEN`) → "Argument list too long". Use `claude -p … < file`
  or a `<<PROMPT` heredoc. Corollary: **cache the expensive step** (the re-plan) under a
  gitignored `.cache/` so a judge-prompt or rubric fix never re-triggers it.

---

# The eval ends in a conversation (both families)

An eval doesn't end at an exit code — it ends with **you reading the report and helping the
human decide what to do next.** This is where the skill's division of labor pays off: the
human knows their project; you know the machinery (what a HURT verdict implies, which shard
to narrow or revert). Don't let a run terminate in silence.

**Why the human runs it, not you.** `run-eval.sh` spawns `claude -p` (the re-plan, the
judge), and an agent in auto mode is blocked from spawning another Claude — so you *can't*
run it, but you *can* read what it wrote. Say this to the human in one breath, so "run this
yourself" doesn't read as you being lazy:

> *I can't run this — it invokes `claude -p`, which an agent in auto mode is blocked from
> spawning. Run it in your shell; the report prints right there, and I'll read it too so we
> can decide the next move together.*

**The handoff, concretely:**

1. The human runs the case (or `run-all.sh`) in their shell. The report prints to their
   terminal immediately and lands at `<case>/.cache/last-report.md`.
2. **You `Read` that file** — proactively, the moment the run returns. Never make the human
   copy-paste it or open it themselves.
3. **You read the verdict and name it:** helped / neutral / hurt, in one line.
4. **You recommend a next action tied to the edit they just made** — keep the shard, refine
   its `USE WHEN` line, or revert it. A HURT verdict means the edit made the plan *worse*;
   the move is usually to narrow or revert, not to keep tuning. The human decides; you act
   (C8).

**Three things to hold as you interpret a report:**

- **It's one draw.** The new plan came from a single nondeterministic `claude -p` re-plan; a
  marginal verdict (a hair better, a hair worse) can flip between runs. Before you recommend
  reverting on a thin margin, say so and re-run once — don't revert a shard on noise.
- **Disagreement is calibration, not friction.** When the human reads the same plans and
  disagrees with the judge's verdict, that's the signal `judge.md` is miscalibrated — fold
  their reasoning into the rubric and note it for the next run. The conversation *is* how the
  judge improves (the human-review layer married to the automated one).
- **Every report is also a backlog.** The judge ends with "what should the Expert have
  contained that would have improved the weaker plan?" — walk those candidates with the
  human and write the shard only if it generalizes (see Family 1).

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
   one-line net read sits on top, emitted as a machine-visible `VERDICT: HELPED | NEUTRAL |
   HURT` line: the Expert edits **helped / were neutral / hurt**. A HURT verdict means an edit
   made the plan *worse* — a successful run with a result to act on (narrow or revert the
   shard), **not** a failed eval; the run still exits 0, and only a broken re-plan or judge
   exits non-zero.

Print the whole report to stdout **and** tee it to `<case>/.cache/last-report.md`, so the
human sees it in their terminal and you can `Read` it — then drive the handoff (*The eval
ends in a conversation*).

**The confound to name out loud.** The old plan was generated *then* (older model, older
spec-planning); the new plan *now*. So "the new plan is better" is not automatically "your
Expert helped." The attribution step is the safeguard: only **shard-traceable** improvements
count as Expert wins; a better-but-unattributable plan is drift. Also surface **what Expert
the baseline had**: a feature that shipped *before* the Expert was seeded shows the whole
Expert's value in one shot; one that shipped *with* a rich Expert shows only your
*incremental* edits. Show the baseline's Expert state so the verdict can be read honestly.

## The rubric (`judge.md` — co-authored, approved before any run)

**The rubric is the work, and it is the developer's.** Open `judge.md` with a one-line note
on what this case froze — the defect or shard under test — so a cold reader of the dir knows
why it exists. Do not draft the rubric alone and present it
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

# Feed the prompt on STDIN (heredoc), never as an argv string. A fixture, code diff, or
# plan pasted into the prompt can exceed Linux's 128 KiB PER-ARGUMENT cap (MAX_ARG_STRLEN,
# separate from ARG_MAX) and abort with "Argument list too long". `<<PROMPT` (or `< file`)
# routes through a pipe, which has no such limit; argv-form `claude -p "$big"` does not.
fix="$(claude -p <<PROMPT
You are fixing a failed check in an unfamiliar repo. The only information you have is
this failure message and the file(s) it names.

===== FAILURE MESSAGE =====
$msg

===== FIXTURE =====
$(cat "$here"/fixture/*)

Describe the exact change you would make, and why.
PROMPT
)"

verdict="$(claude -p --model claude-haiku-4-5 <<PROMPT
$(cat "$here/judge.md")

===== PROPOSED FIX =====
$fix

Answer with a single line: PASS or FAIL: <one-line reason>.
PROMPT
)"

# The verdict is CONTENT, not the exit code. Print the report to the terminal for the human
# and tee it for Claude to Read; exit 0 because the eval RAN — a FAIL verdict is a successful
# run with a result to act on (the message needs WHERE/WHAT/WHY/FIX work). A non-zero exit
# happens only above, when the fixture didn't trip the lint or a `claude -p` call errored.
# See "The eval ends in a conversation" in references/evals.md.
mkdir -p "$here/.cache"
{
  echo "VERDICT: $verdict"
  echo
  echo "===== PROPOSED FIX ====="
  echo "$fix"
} | tee "$here/.cache/last-report.md"
```

---

# The right-reason check (both families — what separates a real eval from a fake one)

`/intent` requires a PRD runner to **fail for the right reason** before the feature
exists. An eval is the mirror:

1. **Its verdict must move when the context moves.** For a long-term-memory case: with the
   shard under test *removed* from the Expert, the new plan should collapse toward the old
   one (the attributable difference disappears); with it *in*, the difference appears and
   the verdict favors it. For a lint case: the verdict line reads FAIL against the misleading
   message and PASS once it's fixed. An eval whose verdict doesn't depend on the context it
   tests proves nothing — it reads as "covered" while covering nothing.
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
