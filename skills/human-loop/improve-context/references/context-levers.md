# The context-lever map

**Hackable seam.** This is the big picture this skill routes across — every lever a
project has for making its harness build better, with the cost model and improvement
moves for each. A project can annotate levers with its own priorities.

The system in one breath: the human expresses intent (`/intent` → PRD + runner); the
harness plans (spec-planning, informed by the **Expert**), implements, self-checks
(`local-checks.sh`), and converges to a PR — or STUCKs. Every one of those stages reads
context this project controls. Improving that context is the compounding move: a code
fix fixes one feature; a context fix upgrades every future feature.

| Lever | Loading | Cost model | Bar |
|---|---|---|---|
| `AGENTS.md` (root + nested) | **Eager** — every session that touches the folder | Paid in tokens whether or not it's relevant | Highest — five predicates |
| The Expert (`.claude/skills/expert/`) | **Lazy** — pulled on demand | Paid only when consulted | Looser — the default home for real knowledge |
| `/intent` (`prds/<f>/prd.md` + `run-prd-test.sh`) | Input to the whole chain | One PRD per feature | Garbage in, garbage out |
| Lints (`scripts/lints/` + `local-checks.sh`) | Deterministic, every check pass | Runs forever, free after authoring | Mechanically checkable only |
| Evals (`evals/`) | Human-invoked | One run per iteration | Measures the other levers |

## AGENTS.md — eager memory

Loaded automatically into every agent session that enters the folder; every line is a
standing tax. A fact earns a line only if **all five predicates** hold: needed *before*
an agent would think to consult the Expert; non-inferable from the code; harmful if
violated (behavior/data, not style); stable; local-or-truly-global. Caps: root ≤ 150
lines, nested ≤ 80 (`scripts/check-agents-md.sh` in `/learn` enforces them).

The **map/territory rule**: AGENTS.md *points into* the Expert, never copies it. A
pointer stays correct as the Expert grows; a copied paragraph drifts.

**Improvement moves:** prune lines that fail a predicate (most do); convert prose rules
into pointers at Expert shards; check traces for agents that never opened the Expert
before a non-trivial decision — that's usually a *missing pointer* here, not an agent
failure.

## The Expert — lazy long-term memory (the biggest lever)

The project's long-term memory, `.claude/skills/expert/` — a routing-table `SKILL.md`
plus one small reference file per topic. Six prefixes map to memory types:
`how-to-*` (procedural), `concept-*` / `pattern-*` / `invariant-*` (semantic — nouns,
soft rules, hard rules), `example-*` (episodic, cited from a real sha), and
`decision-*` (forward-looking direction the code hasn't caught up to yet).

**Long-term memory informs short-term memory:** `/spec-planning` consults the Expert at
the start of every plan, and `/intent` loads it to shape PRDs and runners. This is the
developer's channel for influencing the autonomous chain *without being in the loop* —
what's written here shows up in every future plan.

The memory is **the developer's**. Anything that helps the next agent plan or build
better belongs here — current facts (cited: file paths, shas) *and* decisions,
direction, and aspirations not yet realized in code. Reconcile, don't accumulate: when
reality or intent changes, edit or delete the shard. Encourage the human to update it
rapidly and constantly; `/learn` files in behind them after every merge.

**Improvement moves:** seed an empty Expert (explore the codebase, then interview the
human for what code can't say — direction, tribal knowledge, past scars); capture what
agents keep re-deriving in traces as `how-to-*` shards; write the human's standing
direction as `decision-*` shards (with an *Until fulfilled* note); **retire abandoned
decisions** — ones the project walked away from that no merge ever fulfilled, which
only a human can judge dead (`/learn` retires the fulfilled ones automatically); measure
it all with `evals/expert/` (Tier-1 probe: answer a targeted planning question **with vs.
without** the shard) and, for the real invocation, a few `evals/spec-planning/` cases (see
`evals.md`) — making "did my edits help?" a runnable question graded on intent, not on the
shipped code.

## /intent — the input lever

The project-owned copy at `.claude/skills/intent/` produces the chain's two inputs:
`prds/<f>/prd.md` (why + what) and `prds/<f>/run-prd-test.sh` (the executable definition
of done — the runner *is* the goal the harness converges on). Garbage in, garbage out:
a vague PRD or a weak runner caps everything downstream.

The highest-leverage half is **verification strategy** — how `run-prd-test.sh` knows
"done": e.g. product features drive an end-to-end testing framework the project
standardizes on; refactors lean on `claude -p` LLM-as-judge checks with tuned rubrics;
API work asserts contract conformance. None of this is right the first time — the
recipes live in `.claude/skills/intent/references/runner-recipes.md`, and because the
skill is project-owned, **editing those references is how the project's intent quality
evolves**.

**Improvement moves:** after a feature ships (or STUCKs), ask what the runner failed to
capture or over-specified; fold the answer into the project's `runner-recipes.md` /
`elicitation.md`; standardize a verification pattern per work type (feature / refactor /
bugfix) once one proves out.

## Lints — memory an agent cannot ship past

`scripts/local-checks.sh` runs everything in `scripts/lints/` on every check pass;
structural rules live here (layer direction, parse-at-boundaries, naming, skip-detection
— "UI can't import the repo package" is a classic). A lint is the strongest memory form:
enforced deterministically, forever.

**The error message is a prompt.** On failure, the message is all a cold
`/fix-local-checks` agent gets — it must carry WHERE / WHAT / WHY / FIX / DON'T-CHEAT
(see `env-init/references/local-checks-design.md` for the template). A terse "rule
violated" leaves the fixing agent guessing, burns attempts, and manufactures STUCKs.

**Improvement moves:** promote a rule to a lint only on recurrence and only if
mechanically checkable (it must pass against current code before wiring in); audit
messages by reading them cold — could you fix the violation from the message alone?;
test exactly that with `evals/lints/` (see `evals.md`).

## STUCK anatomy — what the harness hands you

A STUCK is a *finished* state: a step hit its retry cap and the dispatcher halted the
feature honestly instead of faking success. Caps (defaults, overridable in
`.harness/env`): spec-planning 2 · spec-validate 2 · implement 3 · local-checks 2 ·
feedback 5.

The STUCK comment on the PR carries: the step and cap, a **session table**
(`| Time | Step | Attempt | Session ID | Exit |`) posted deterministically by the
dispatcher, and a tail of the failing output. Each session ID maps to a local trace at
`~/.claude/projects/<encoded>/<session-id>.jsonl` — `scripts/resolve-sessions.sh`
resolves them. The PR comment is the durable contract; the harness repo's
`state/<env>/sessions-<f>.tsv` is ephemeral and deleted on cleanup.

Forensics discipline: `stuck-forensics.md`. The fix ordering is always diagnosis-first
(context, then code) — the merge carries both, and `/learn` makes the context fix
permanent.

## Evals — the lever that measures the levers

Evals form a **pyramid** whose folder tree mirrors the levers above, all graded against a
**developer-intent rubric** (never the shipped code — that's circular). **Tier 1** is one
cheap family per lever: `evals/expert/` and `evals/agents-md/` ablate a shard/line ("does
the plan honor it, with vs. without?"), `evals/intent/` gates a PRD/runner's sufficiency,
`evals/lints/` asks "does this lint message work as a fix-prompt read cold?". **Tier 2** is
a few `evals/spec-planning/` integration cases — the real `/spec-planning` invocation where
all levers converge. Committed to the project and run where the human is: the fast feedback
loop that tells the developer whether their context edits are actually helping, without
waiting for production PRs. Full contract: `evals.md`.
