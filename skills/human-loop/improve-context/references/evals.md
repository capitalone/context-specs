# The eval contract

An eval is the load-bearing artifact of continuous improvement: it freezes *"given this
context, the harness should behave like this"* so a future context change can't silently
regress it — and so a context edit's value is **measurable** instead of vibes. This is
the observe → capture-an-eval → fix-the-context → it-persists flywheel, where the
"prompt" being tuned is the project's own context.

> Governing principle: **an eval tests the harness's own context, not the product.**
> A PRD runner (`prds/<f>/run-prd-test.sh`) asks "does the *feature* work?". An eval asks
> "given this context, does the *harness* behave as it should?". Different question,
> different home — keep them separate so neither rots the other.

**Why this is exciting (tell the human).** Authoring an eval is the moment their *own
project* becomes an agent harness they can evaluate and improve: each eval is a graded
trial of the project's context that compounds — the project gets better at building
itself over time.

## Ground truth is the developer's intent, never the shipped code

The one rule that shapes everything below: **an eval grades a plan against a rubric of
the developer's intent** — how the system should behave, its conventions, its direction —
**co-authored with the human and owned by them.** It never grades against the shipped
code as a golden reference. Grading against shipped code is circular: a lesson you just
added to the Expert is *already baked into the code*, so "the new plan matches the code"
proves nothing but that the loop closed on itself. The diff is at most *evidence* that
helps the human articulate a criterion — it is never the answer key.

**The anti-overfit rule — reward the EFFECT, not the ECHO.** A criterion must test the
downstream outcome a shard exists to *produce*, grounded in a concrete locus in the plan
that could *plausibly fail* — never the presence of the shard's words.

> Shard: *"dates must be timezone-safe."*
> ❌ Echo (overfit / circular): "does the plan mention timezone-safety?" — a plan can
>    recite it and still design the DST bug in; with-context trivially "passes."
> ✅ Effect (discriminating): "does the plan's storage + query approach actually avoid
>    the DST bug — store UTC, convert at the edges?" — a plan can pass via a *different*
>    route; a plan that name-drops timezones but stores local time *fails*.

If two engineers couldn't independently reach the same verdict from the plan alone
(the **task-writability test**), the criterion is echo-shaped — don't freeze it yet.

## The pyramid — two tiers

Evals form a pyramid, the same shape as unit-vs-integration tests:

```
        ╱ Tier 2 — spec-planning (integration): all levers, one plan.  ╲
       ╱   Invoke /spec-planning the harness's way; judge the whole     ╲
      ╱    plan. Expensive, realistic. FEW (3–5), span work types.       ╲
     ╱───────────────────────────────────────────────────────────────────╲
    ╱  Tier 1 — one lever each: expert · agents-md · intent · lints.       ╲
   ╱   Cheap, targeted, MANY. A tiny scenario probes a single context      ╲
  ╱    lever directly. Where most cases live, and your coverage map.        ╲
 ╱─────────────────────────────────────────────────────────────────────────╲
```

The tier boundary is **single-lever vs. all-levers-integrated.** Tier 1 interrogates one
lever in isolation (cheap enough to have one per load-bearing shard); Tier 2 runs the real
`/spec-planning` invocation where all four levers converge into a plan (expensive, so kept
few). Tier 2 is also the anti-overfit backstop for Tier 1: a full coherent plan can't win
by keyword-stuffing the way a single-criterion probe might.

## Where evals live — in the project, mirroring the lever surface

Evals live in the **dev's project**, under `evals/` at the repo root — a runtime artifact
of the project, like `prds/` and `specs/`. Human-in-the-loop, run from the user's own
checkout. The folder tree is **flat by lever**, so it *is* the coverage map — open
`evals/`, see your project-owned context levers, see how many cases guard each:

```
<project-repo>/evals/
├── README.md            # the contract, for humans who find the dir cold
├── run-all.sh           # aggregator; `--tier1` runs only the cheap families
├── expert/              # Tier 1 · feedforward guide · with/without compare
│   └── <behavior-slug>/{fixture/, judge.md, run-eval.sh}
├── agents-md/           # Tier 1 · feedforward guide · with/without compare
│   └── <behavior-slug>/{fixture/, judge.md, run-eval.sh}
├── intent/              # Tier 1 · input · absolute gate  (thin — 1–2 to start)
│   └── <behavior-slug>/{fixture/, judge.md, run-eval.sh}
├── lints/               # Tier 1 · feedback sensor · absolute gate
│   └── <lint-name>/{fixture/, judge.md, run-eval.sh}
└── spec-planning/       # Tier 2 · integration · with/without compare · FEW
    └── <behavior-slug>/{fixture/, judge.md, run-eval.sh}
```

The five families map onto the project's **evaluable levers** (`context-levers.md`):
`AGENTS.md`, the Expert, `/intent`, and lints. (Evals themselves measure the levers, so
they aren't evaled.) Case names are behavior slugs
(`spec-planning-honors-ssr-constraint`), not feature names.

### Scaffolding `evals/` on first use

If the project has no `evals/` dir yet, create it with the first eval — a `README.md` and
`run-all.sh`, committed on the same branch as the eval.

`evals/README.md` (project-facing — adapt the wording):

```markdown
# `evals/` — regression tests over this project's harness context

Authored with `/improve-context` when a build trail, a STUCK, or a context edit reveals
something worth freezing. Evals test the **harness** ("given this context, does it
behave?"); `prds/<f>/run-prd-test.sh` tests the **product** ("does the feature work?").
Keep them separate.

Two tiers, one folder per project-owned lever:
- **Tier 1 — single-lever checks (cheap, many)** — `expert/`, `agents-md/`, `intent/`,
  `lints/`: each probes a single context lever in isolation.
- **Tier 2 — whole-plan checks (expensive, few)** — `spec-planning/`: the real
  `/spec-planning` invocation, where all levers converge into a plan.

Ground truth is a **developer-intent rubric** in each case's `judge.md`, never the shipped
code. Contract: one dir per case — `<family>/<case>/{fixture/, judge.md, run-eval.sh}`.
`run-eval.sh` prints a **report** (to the terminal and to `<case>/.cache/last-report.md`)
whose **verdict line** — `HELPED | NEUTRAL | HURT` (with/without families) or `PASS | FAIL`
(gate families) — is the signal; the exit code only says whether the case *ran*. Read the
report and discuss it. A new eval's verdict must MOVE with the context it tests.
```

`evals/run-all.sh`:

```bash
#!/usr/bin/env bash
# Run every eval case and print each report. This is a RUNNABILITY smoke test, not a
# quality gate: a case exits non-zero only when it couldn't RUN. The helped/hurt (or
# pass/fail) verdict lives inside each report — read it and discuss it (references/evals.md).
#   --tier1   run only the cheap single-lever families (skip spec-planning/)
# Exit 0 iff every case that ran, ran cleanly.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
tier1_only=0; [[ "${1:-}" == "--tier1" ]] && tier1_only=1
families=(expert agents-md intent lints)
(( tier1_only )) || families+=(spec-planning)
broke=0 ran=0
for fam in "${families[@]}"; do
  for runner in "$here/$fam"/*/run-eval.sh; do
    [[ -e "$runner" ]] || continue
    ran=$((ran + 1)); name="${runner#"$here"/}"; name="${name%/run-eval.sh}"
    echo "===== [$fam] $name ====="
    if bash "$runner"; then echo "ran    $name"; else echo "BROKE  $name (couldn't run — not a verdict)"; broke=1; fi
  done
done
(( ran == 0 )) && echo "no evals yet (evals/<family>/<case>/run-eval.sh)"
exit $broke
```

## The runner contract (all families)

`run-eval.sh` shares `run-prd-test.sh`'s *runnable-file* shape — one script under the case
dir you invoke directly — but its **signal is different on purpose.** A PRD runner's exit
code is a **binary gate the harness consumes** ("does the feature work? exit 0, or the
build stops"). An eval asks a question a human and Claude **discuss.** So the eval's output
contract is a report, not an exit code:

- **Primary output = a report, printed to the terminal AND tee'd to a file.** The full
  report goes to stdout so the human sees the result the instant the run ends — never "go
  open a file." It is *also* written to a gitignored `<case>/.cache/last-report.md` so
  Claude can `Read` it directly and drive next steps.
- **The verdict lives inside the report, as content.** A machine-visible line — `VERDICT:
  HELPED | NEUTRAL | HURT` for a with-and-without family, `PASS | FAIL: <reason>` for a
  gate family — is what Claude reads and the human reacts to. It is *not* the exit code.
- **A `claude -p` arm names its session id in the report, and the report ends with a
  "reply `done`" footer.** For the families that *invoke* Claude to produce an arm (`expert/`,
  `spec-planning/`), print each arm's `--session-id` so the skill can resolve the trace
  (`~/.claude/projects/*/<id>.jsonl`) and read *why* an arm answered as it did — the tie-breaker
  for a NEUTRAL. The footer tells the human to return to the session and reply `done`, closing
  the human→session loop instead of leaving the report to be discovered.
- **Exit code = operational success only.** Exit 0 = the eval *ran* and produced a report;
  non-zero *only* when it couldn't run (a crashed re-plan or judge, a fixture that didn't
  trip a lint). A HURT / FAIL verdict is a successful run with a bad result — it still
  exits 0. Nothing automated consumes this code; it exists so `run-all.sh` can flag a case
  that is *broken*, not one whose context underperformed.
- **Internals are free** — deterministic checks, a `claude -p` judge, or a mix.
- **Self-contained under the case dir.** Fixtures, judge prompt, helpers all live beside
  the runner, sandboxed from the project's own test discovery.
- **Feed a judge prompt on STDIN, never as an argv string.** An eval prompt bundles big
  inputs (both plans, the shards in scope) and blows past Linux's 128 KiB per-argument cap
  (`MAX_ARG_STRLEN`) → "Argument list too long". Use `claude -p … < file` or a `<<PROMPT`
  heredoc. Corollary: **cache the expensive step** (the re-plan) under a gitignored
  `.cache/` so a judge-prompt or rubric fix never re-triggers it.

---

# The eval ends in a conversation (all families)

An eval doesn't end at an exit code — it ends with **you reading the report and helping the
human decide what to do next.** This is where the skill's division of labor pays off: the
human knows their project; you know the machinery (what a HURT verdict implies, which shard
to narrow or revert). Don't let a run terminate in silence.

**Why the human runs it, not you.** `run-eval.sh` spawns `claude -p` (the probe, the
re-plan, the judge), and an agent in auto mode is blocked from spawning another Claude — so
you *can't* run it, but you *can* read what it wrote. Say this to the human in one breath:

> *I can't run this — it invokes `claude -p`, which an agent in auto mode is blocked from
> spawning. Run it in your shell; the report prints right there. When it finishes, come back
> here and reply `done` — I'll read the report and the reasoning traces and we'll decide the
> next move together.* (The report's own footer says the same, so it's on screen when the run
> ends.)

**The handoff, concretely:**

1. The human runs the case (or `run-all.sh`) in their shell. The report prints to their
   terminal immediately and lands at `<case>/.cache/last-report.md`.
2. **You `Read` that file** — proactively, the moment the run returns. Never make the human
   copy-paste it.
3. **You read the verdict and name it:** helped / neutral / hurt (or pass / fail), in one line.
4. **You recommend a next action tied to the edit they just made** — one of **keep · refine
   the `USE WHEN` line · delete the shard · consolidate it into a sibling · revert**. A HURT
   verdict means the edit made the plan *worse* — usually narrow or revert. The human decides;
   you act.

**NEUTRAL is not a dead end — it's a fork, and the reasoning traces resolve it.** A NEUTRAL
means arm A and arm B came out equivalent, but *why* determines the move, so `Read` the two
session traces the report names (`~/.claude/projects/*/<id>.jsonl` — resolve by id) whenever
the verdict is ambiguous or the human disputes it (skip it when the verdict is obvious):

- **The shard WAS consulted and the answer didn't change** → the model already knows this
  (or a sibling covers it). The shard is redundant → **recommend deleting it** (and this
  eval case). Lean toward delete — a shard that earns nothing is standing noise. *Exception:*
  keep it if it states **direction/decision** the model wouldn't infer, even when today's
  output already complies.
- **The shard was NEVER routed to** (`/expert` opened other files, not this one) → the
  content may be fine; the **`USE WHEN` line missed**. → refine the routing line, re-run.
- **A sibling shard restated the rule** (you'll see it opened in the trace) → the two overlap
  → **consolidate**: promote any unique detail into the sibling and delete the rest.

**Three things to hold as you interpret a report:**

- **It's one draw.** A plan came from a single nondeterministic `claude -p`; a marginal
  verdict can flip between runs. For the *cheap* Tier-1 probes, prefer running a few trials
  and reading the majority. For Tier-2, before you recommend reverting on a thin margin, say
  so and re-run once — don't revert a shard on noise.
- **Disagreement is calibration, not friction.** When the human reads the same plans and
  disagrees with the judge, that's the signal `judge.md` is miscalibrated — fold their
  reasoning into the rubric and note it for the next run. The conversation *is* how the
  judge improves.
- **Every report is also a backlog.** The judge ends with "what should the context have
  contained that would have improved the weaker output?" — walk those candidates with the
  human and write the shard only if it generalizes.

---

# Tier 1 — one lever each

Every Tier-1 case is small, cheap, and probes **one** context lever. The runner shape and
scoring mode fall out of the lever's role (`context-levers.md`): **feedforward guides**
(Expert, AGENTS.md) steer the plan *before* the work, so we compare with vs. without (does
removing this context make the output worse?); **inputs and sensors** (`/intent`, lints) are
graded as artifacts against an absolute bar.

Among the guides, the lever's **eager-vs-lazy** nature picks the mechanism. `AGENTS.md` is
*eager* — always loaded — so pasting the line into the probe is faithful. The Expert is
*lazy* — `/expert` routes to shards on demand — so its probe must **invoke the real skill**
and let it route, or it would never test the routing that decides whether the shard is even
seen. That is why `expert/` runs `probe-expert.sh` (below) while `agents-md/` just feeds text.

## `expert/` — did a shard steer the plan, for the better? (with vs. without)

The Expert is the biggest lever, and unlike AGENTS.md it is **lazy** — `/expert` is a skill
with a routing table, and the agent *chooses* which shards to open by matching `USE WHEN`
lines. So the faithful probe doesn't paste the shard's text in; it **invokes the real
`/expert` skill** and lets it route. That tests two things a text probe can't: whether the
shard's content changes the plan *and* whether the routing table actually surfaces it.

`scripts/probe-expert.sh` (this skill's own, sibling to `plan-in-isolation.sh`) does this in
a **minimal sandbox** — a throwaway dir holding ONLY `.claude/skills/expert` (a copy of the
working-tree Expert), no codebase. It `cd`s in and runs one `claude -p` that must consult
`/expert`, then answer the scenario's planning question. Two payoffs: it's cheap (it skips
the whole-codebase analysis that makes Tier-2 slow — the reason we can afford one per shard),
and the baseline arm is **hermetic** — with no codebase and the shard removed there is
nothing on disk to leak the rule back, so a NEUTRAL means the model already knew it.

Two baseline modes (arm A is always the current Expert):

- **with/without** (`--without <shard>`) — arm B removes the shard file, strikes its
  routing-table row, and **de-links inbound `[[shard]]` references** in sibling shards (a
  dangling wikilink would tell the baseline "a rule lived here"). Sibling *prose* that
  independently states the rule is left intact — that redundancy is a real signal, not a leak
  to scrub. Use for a shard you're **adding or weighing deleting**.
- **version-vs-version** (`--prev <shard> --prev-from <ref|path>`) — arm B swaps the shard to
  an **older** version (a git ref, or a file), keeping the routing row so routing cancels and
  the **wording delta** is what's judged. Use when you **edited** a shard and want to know if
  the edit actually improved it — something with/without can't tell you. *Confirm with the
  human which revision is "old"* (HEAD vs. a `.cache` snapshot) before running.

- **`fixture/`** — `scenario.md` (a planning question, LLM-drafted and human-steered) and
  `shard-under-test` (the shard's relpath under the Expert root). Add a `prev-from` file (a
  git ref or path) to switch the case into version-vs-version mode.
- **Faithfulness note:** this probe tests the Expert's routing + content *in isolation*.
  Whether the FULL `/spec-planning` — with the codebase and every other lever competing for
  attention — still surfaces the shard is the Tier-2 question.

Skeleton `run-eval.sh`:

```bash
#!/usr/bin/env bash
# Invoke the REAL /expert skill in isolation, arm A (current Expert) vs arm B (shard removed,
# or swapped to its previous version), and judge the two answers blind. Signal = the VERDICT
# line; exit code is operational only. Run from a human shell (spawns `claude -p`).
#   REFRESH=1 bash run-eval.sh   # regenerate both arms (else cached)
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(git rev-parse --show-toplevel)"
probe="$root/.claude/skills/improve-context/scripts/probe-expert.sh"
scenario="$here/fixture/scenario.md"
shard="$(cat "$here/fixture/shard-under-test")"     # relpath under the Expert skill root
mkdir -p "$here/.cache"

# probe-expert.sh writes answer.txt + session-id under each out-dir. Cache both arms so a
# judge/rubric edit doesn't re-trigger the expensive probe (REFRESH=1 forces a re-run).
run_arm() {  # $1 = cache subdir; rest = probe baseline flags
  local out="$here/.cache/$1"; shift
  [[ -s "$out/answer.txt" && "${REFRESH:-0}" != "1" ]] && return 0
  bash "$probe" "$scenario" "$out" "$@" >/dev/null || { echo "arm $1 failed to run"; exit 1; }
}
run_arm A                                            # arm A: current Expert
if [[ -f "$here/fixture/prev-from" ]]; then          # arm B: baseline
  run_arm B --prev "$shard" --prev-from "$(cat "$here/fixture/prev-from")"
else
  run_arm B --without "$shard"
fi
A="$(cat "$here/.cache/A/answer.txt")"; B="$(cat "$here/.cache/B/answer.txt")"
sidA="$(cat "$here/.cache/A/session-id")"; sidB="$(cat "$here/.cache/B/session-id")"

# Blind, order-swapped pairwise judge on the discriminating criterion in judge.md.
judge() {  # $1,$2 = the two answers in presentation order
  claude -p --model claude-haiku-4-5 <<PROMPT | grep -oE 'WINNER:[[:space:]]*(A|B|TIE)' | grep -oE '(A|B|TIE)' | tail -1
$(cat "$here/judge.md")
Two answers, labeled A and B (order randomized; don't assume which is which).
===== A =====
$1
===== B =====
$2
Write a one-paragraph critique grounded in the criterion (judge its EFFECT, not whether the
words appear), THEN end with exactly one line: "WINNER: A", "WINNER: B", or "WINNER: TIE".
PROMPT
}
w1="$(judge "$A" "$B")"; w2="$(judge "$B" "$A")"     # order-swapped: with-as-A, then with-as-B
[[ -n "$w1" && -n "$w2" ]] || { echo "judge emitted no WINNER line"; exit 1; }
case "$w1" in A) r1=with;; B) r1=without;; *) r1=tie;; esac
case "$w2" in A) r2=without;; B) r2=with;; *) r2=tie;; esac
case "$r1:$r2" in
  with:with)       verdict="HELPED";;
  without:without) verdict="HURT";;
  *)               verdict="NEUTRAL";;               # position-bias disagreement or a real tie
esac

{ echo "VERDICT: $verdict   (shard under test: $shard)"
  echo "reasoning traces — arm A (with): $sidA   arm B (without/prev): $sidB"
  echo; echo "===== ARM A (with shard) ====="; echo "$A"
  echo; echo "===== ARM B (without / previous version) ====="; echo "$B"
  echo; echo "-----"
  echo "Above are the two answers /expert produced, with and without the shard. To decide"
  echo "what to do, return to the Claude session that wrote this eval and reply 'done' — it"
  echo "will read this report AND the reasoning traces above, then help you choose: keep,"
  echo "refine the USE WHEN line, delete the shard, or consolidate it into a sibling."
} | tee "$here/.cache/last-report.md"
```

## `agents-md/` — is an eager line honored? (with vs. without)

Same shape as `expert/`, but the lever is a line (or block) of `AGENTS.md`, which is
*eager* — always loaded — so feeding it to the probe is faithful. Arm A includes the line;
arm B strips it. The criterion tests whether the plan *obeys* the rule, not whether it
quotes it. (`fixture/` holds the scenario + the AGENTS.md excerpt with the line marked.)

## `intent/` — is the PRD/runner a sufficient, right-reason spec? (absolute gate)

`/intent` produces the chain's inputs — `prds/<f>/prd.md` and `run-prd-test.sh` — and
garbage in caps everything downstream. This family grades an **artifact** against an
absolute bar, so its verdict is `PASS | FAIL`, not a comparison. Keep it **thin** (1–2
cases to start): the question is well-defined but the rubric takes iteration.

- **`fixture/`** — a PRD + runner (real or LLM-drafted, human-steered).
- **The judge** checks sufficiency: is the PRD unambiguous about the "what"; does the runner
  encode a real definition-of-done that would **fail for the right reason** before the
  feature exists; does the verification strategy fit the work type
  (`intent/references/runner-recipes.md`)? An "Unknown" answer is allowed when the artifact
  omits the information.
- Optional with/without variant: strip a `runner-recipe` the project standardized on and
  check whether the produced runner degrades — that turns this into a guide-style
  with/without check for the
  `/intent` references, which *are* a project-owned lever.

## `lints/` — is the error message a sufficient prompt? (absolute gate)

A lint's failure message is the *prompt* a cold `/fix-local-checks` agent acts on — it has
no other context. This family tests exactly that property:

1. **Fixture:** a minimal mocked violation of the lint (a file or small tree under
   `fixture/` that the lint should flag).
2. **Run the lint** against the fixture; capture its failure message.
3. **Feed ONLY the message** (plus the fixture) to a cold `claude -p` — no Expert, no
   AGENTS.md, no conversation: exactly what `/fix-local-checks` gets.
4. **Judge:** did the agent correctly diagnose the violation and produce the right fix from
   the message alone — without silencing (`judge.md` names the silencing trap for this rule)?

A FAIL here means the message needs WHERE / WHAT / WHY / FIX / DON'T-CHEAT work (see
`env-init/references/local-checks-design.md`), not that the lint's rule is wrong.

Skeleton `run-eval.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"

msg="$(bash "$(git rev-parse --show-toplevel)/scripts/lints/<lint>.sh" "$here/fixture" 2>&1)" && {
  echo "fixture did not trip the lint — fixture or lint is broken"; exit 1; }

# Feed the prompt on STDIN (heredoc), never as an argv string — a fixture pasted into an
# argv can exceed Linux's 128 KiB PER-ARGUMENT cap (MAX_ARG_STRLEN) and abort with
# "Argument list too long". `<<PROMPT` (or `< file`) routes through a pipe, no such limit.
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

# The verdict is CONTENT, not the exit code. Print the report and tee it; exit 0 because
# the eval RAN — a FAIL is a successful run with a result to act on. Non-zero only above,
# when the fixture didn't trip the lint or a `claude -p` errored.
mkdir -p "$here/.cache"
{ echo "VERDICT: $verdict"; echo; echo "===== PROPOSED FIX ====="; echo "$fix"; } \
  | tee "$here/.cache/last-report.md"
```

---

# Tier 2 — `spec-planning/`: all levers, one plan (integration, with vs. without)

**What's judged: the plan, never a re-implementation.** The context (Expert + AGENTS.md +
the PRD) informs `/spec-planning`, whose output is the plan (mainspec + slices). The plan is
the context's direct causal output, so the plan is what gets graded — re-running
implementation would add cost, nondeterminism, and two confounders (the implementer, the
environment) between the thing changed and the thing measured. Production already grades the
outer loop (attempt counters, STUCK rate).

**The comparison is with-vs-without at HEAD.** Re-plan a feature **twice, now, against HEAD**:
arm A with the project's current context, arm B with the shard/line under test removed. Both
plans are produced by the real `/spec-planning` invocation, so this tier catches what a probe
structurally can't — whether the shard actually *surfaces at the right moment* in a real plan,
or gets crowded out. Both arms are generated in the same run against HEAD, differing only by
the shard/line under test, so the delta between them is attributable to that context alone —
nothing else moved. That delta is the attribution.

## The runner — this skill's own `plan-in-isolation.sh` does the heavy lifting

Re-running `/spec-planning` headless has two traps, and both are why the shared helper
**inspects the harness this environment runs under** instead of hardcoding `claude -p` flags:

1. The harness's tier-1 skills (incl. `spec-planning`) reach a project as **gitignored
   symlinks** in `.claude/skills/`. A fresh worktree doesn't carry them, so
   `claude -p "/spec-planning …"` answers **"Unknown command."** — the checkout must be
   re-linked (`context-specs link`, or the project's `scripts/bootstrap-worktree.sh`).
2. The right permission posture is the **harness's**: default `--permission-mode auto`,
   overridable per-environment in `.harness/env`. Never hardcode
   `--dangerously-skip-permissions`; read the effective `CLAUDE_PERM_ARGS`.

This skill's own `scripts/plan-in-isolation.sh` (in the skill folder — **not** the project's
repo-root `scripts/`) does all of this. Given a feature it spins a *disposable*
worktree at **HEAD** (not a harness-managed one), overlays the env's current working-tree
Expert, links the skills, invokes `/spec-planning <feature>` the harness's way, captures
`specs/<f>/` off disk, and deletes the worktree. With `--without <relpath>` it removes that
context file (a shard, or an AGENTS.md overlay) before planning — that's arm B. A case's
`run-eval.sh` calls it twice:

```bash
#!/usr/bin/env bash
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(git rev-parse --show-toplevel)"
feature="$(cat "$here/fixture/feature")"          # a merged OR in-progress feature slug
shard="$(cat "$here/fixture/shard-under-test")"   # relpath under .claude/skills/expert/, or an AGENTS.md marker
mkdir -p "$here/.cache"

# Cache the arms — a judge/rubric edit must NOT re-trigger a re-plan.
[[ -d "$here/.cache/A/plan" ]] || bash "$root/skills/human-loop/improve-context/scripts/plan-in-isolation.sh" \
  "$feature" "$here/.cache/A"                       # arm A: current context
[[ -d "$here/.cache/B/plan" ]] || bash "$root/skills/human-loop/improve-context/scripts/plan-in-isolation.sh" \
  "$feature" "$here/.cache/B" --without "$shard"    # arm B: shard removed

# Blind, order-swapped pairwise judge on the co-authored intent rubric.
verdict="$(claude -p <<PROMPT
$(cat "$here/judge.md")
Two spec plans, labeled A and B (order randomized). Judge each rubric criterion as a
comparison (A better / B better / tie) with a citation to the plan text. Judge the shard's
EFFECT on the plan, not whether the plan quotes it. End with:
VERDICT: HELPED | NEUTRAL | HURT
===== PLAN A =====
$(cat "$here/.cache/A/plan/mainspec.md"; echo; cat "$here"/.cache/A/plan/slices/* 2>/dev/null)
===== PLAN B =====
$(cat "$here/.cache/B/plan/mainspec.md"; echo; cat "$here"/.cache/B/plan/slices/* 2>/dev/null)
PROMPT
)"
{ echo "$verdict"; echo; echo "(plans cached under .cache/A, .cache/B)"; } | tee "$here/.cache/last-report.md"
```

> **Run these from a human shell.** The helper launches an autonomous, file-writing
> `claude -p`; an agent in auto mode is blocked from spawning it. Tier-2 cases cost minutes
> and real tokens and are **not** part of `scripts/local-checks.sh`.

## The rubric (`judge.md` — co-authored, approved before any run)

**The rubric is the work, and it is the developer's.** Open `judge.md` with a one-line note
on what this case froze — the intent or shard under test — so a cold reader knows why it
exists. Do not draft it alone and present it; build it *with* the human, iterate, get
explicit sign-off *before* running. Seed it from ground truth you put in front of them: the
**PRD + runner** (the why/what) and, as *evidence not answer key*, the **code diff** — walk
it with them to elicit criteria, never to make "match this code" a criterion.

The spine is three criteria (add project-/feature-specific ones live, with the human):

1. **Sufficiency for correctness** — would an implementer following this plan plausibly
   reach an implementation that passes `run-prd-test.sh`? (Grounded in the runner.)
2. **Sufficiency for quality** — does the plan steer toward the bar the project holds:
   reusing what exists, honoring the `invariant-*` / `pattern-*` shards in scope, not
   reinventing? (Grounded in the Expert + conventions.)
3. **The intent under test** — the discriminating, effect-not-echo criterion this case was
   built to protect.

Judge each criterion as a **comparison** (A better / B better / tie) with a citation. No
absolute scores, no passing on vibes. Deliberately **excluded**: plan-structure polish
(slice sizing, ordering) — that measures `/spec-planning`, not the context.

---

# Judge design (all families)

The judge is an LLM; these are the guardrails that keep it honest (grounded in the eval
literature — Hamel Husain's LLM-as-judge, Anthropic's demystifying-evals):

- **Binary, atomic criteria.** One construct per check, pass/fail — not a 1–5 scale that
  clusters and drifts. Decompose "quality" into separate checks.
- **Critique before verdict.** Make the judge write its reasoning, grounded in a plan locus,
  *then* emit the verdict line. The critique is where miscalibration becomes visible.
- **Grade the effect, not the echo** (the anti-overfit rule above) — and neutralize
  verbosity: a longer plan is not a better one.
- **Give it an "Unknown" out.** When the plan lacks the information, "Unknown" beats a
  hallucinated grade.
- **Order-swapped pairwise.** Label the arms A/B, randomize order; for a rigorous case,
  judge both orders and call it a **tie** when they disagree — that kills position bias.
- **Isolate per criterion** where it matters — one judge call per dimension rather than one
  call grading everything, so criteria don't bleed.

---

# The right-reason check — what separates a real eval from a fake one

`/intent` requires a PRD runner to **fail for the right reason** before the feature exists.
An eval is the mirror: **its verdict must move when the context moves.**

- For a **with-and-without family** (`expert/`, `agents-md/`, `spec-planning/`) this is *structural*
  — the baseline arm already has the shard removed, so if the shard does nothing, the arms
  converge and the verdict is NEUTRAL; if it does something, the delta appears and the
  verdict favors the with-shard arm. You get the red-before/green-after for free. If you
  *can't* make the verdict move by adding/removing the shard, you haven't isolated the
  intent yet — go back to the scenario and the criterion.
- For a **gate family** (`intent/`, `lints/`) the verdict must read FAIL against the weak
  artifact/message and PASS once it's fixed.

An eval whose verdict doesn't depend on the context it tests proves nothing — it reads as
"covered" while covering nothing. And a pairwise win that comes from the shard's *echo*
rather than its *effect* is the same failure wearing a passing verdict.

## Population — which cases to create

Coverage is a **taxonomy of intents, not a count of features.** Three sources feed it:

1. **Mirror the context.** Every load-bearing shard (`invariant-*`, `pattern-*`,
   `decision-*`) and every eager `AGENTS.md` line is a testable claim → a candidate Tier-1
   case. This makes the eval tree a mirror of the context the skill manages, and coverage
   legible ("which shards are guarded?"). Safe *because* of the effect-not-echo rule — you
   test what the shard achieves, not that a plan can read it.
2. **Developer scenarios.** The recurring work types the project does (add an endpoint, a
   migration, a refactor) and the intent each must honor — forward-looking, LLM-drafted and
   human-steered. These seed the few Tier-2 cases especially.
3. **Real rejections and STUCKs.** A plan the developer rewrote, or a genuine STUCK
   diagnosis that landed on "context gap" — each encodes an intent violation. An *optional*
   seed now, not the mechanism.

Always pair a should-fire case with a **should-not-fire** negative where the intent is out
of scope — one-sided evals create one-sided optimization (a shard that "wins by always
firing").

## When NOT to write an eval

- The finding was **inherent difficulty**, not a context defect — nothing to freeze.
- The behavior is already covered — extend the existing `judge.md` instead of spawning a
  near-duplicate.
- The fix is a **lint** (mechanically checkable). The lint *is* the regression test for the
  rule — an `evals/lints/` case tests the lint's *message quality*, a different question.
- The criterion fails the **task-writability test** — two engineers couldn't agree on the
  verdict from the plan alone. Sharpen it or drop it.

A clean trail, or a trail whose only finding is "this was hard," produces **no eval**. That
is a correct and common outcome.

## Suite discipline

Tier 1 grows freely (one per load-bearing shard); **Tier 2 stays small** — 3–5 cases
spanning work types (a product feature, a refactor, a bugfix). Don't chase volume; every
case is a vector that shifts behavior.

**Rubric validity is checked against the outer loop.** The harness's production attempt
counters and STUCK rate are the ground truth: if eval verdicts trend "context helped" over
time but implement attempts don't fall, the rubric is measuring the wrong thing — fix
`judge.md`, not the suite.
