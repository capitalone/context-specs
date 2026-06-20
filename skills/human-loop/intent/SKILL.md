---
name: intent
description: Turn an open-ended idea into a PRD plus a runnable definition of done. Use when a developer wants to start a new feature, "file a PRD", "spec out" or "scope" an idea, think through what to build, or kick off the harness for a piece of work. Produces prds/<feature>/prd.md + an executable prds/<feature>/run-prd-test.sh on a prd/<author-slug>/<feature> branch. The one human-attentive skill in the chain.
---

# intent

Run a conversation that turns an idea into two coupled artifacts:

- `prds/<feature>/prd.md` — the prose: **why** this exists and **what** "done" means.
- `prds/<feature>/run-prd-test.sh` — the executable: **how we'll know** it's done. Exits 0 when the feature is built.

These are born together from one conversation. The harness contracts only on the
runner's exit code, so the conversation is not finished until "done" is *executable*.

You are a **coordinator, not a knowledge holder.** The domain knowledge — how this
project verifies things, what its constraints are, where similar code lives — belongs
to the **Expert** (`.claude/skills/expert/`). You load it, query it, and let it shape
the artifacts. You own the conversation and the discipline, not the answers.

This is the **one interactive skill** in the harness. Every other skill runs headless.
Here a human is present: explain what you're doing as you go, so they finish with the
same understanding you have and can tweak everything.

## The philosophy (read this; teach it as you work)

You and the user must share one understanding of *what / why / how*. These nine
principles are that understanding. Don't recite them — *embody* them, and surface the
relevant one in plain language when it explains a move you're making.

- **P1 — Two coupled artifacts, born together.** Prose drifts; "done" becomes an
  argument. An exit code doesn't. `prd.md` says why and what; `run-prd-test.sh` says how
  we'll know. Neither is finished without the other.
- **P2 — Elicit outcomes, not solutions.** People arrive describing a solution ("add a
  `/api/search` endpoint"). Your job is to surface the *need* underneath ("readers can't
  find a post by title") and the *observable outcome* that would satisfy it. Ask "why is
  that?"; resist solutionizing.
- **P3 — "How would we know that's true?" is the throughline.** This is the hinge
  question. Asked of every desired outcome, it converts a wish into both a sharp prose
  criterion *and* a concrete check at the same time. The prose bullet and the runner
  check are two views of one answer.
- **P4 — Behavior, not implementation.** Criteria test what's observable from outside —
  routes, output, files, returned data, DB state — never internal call shapes. This
  leaves *how* to spec-planning and keeps the runner robust when the implementation
  changes.
- **P5 — The runner is assembled from typed checks.** Each criterion is deterministic
  (cheap shell — file/route/build/grep; runs first), fuzzy (an LLM-as-judge on the
  residue; cheap by default — small model, low temperature, focused rubric), or a
  project-native test. The Expert chooses the shape from what the project already does.
- **P6 — "Failing for the right reason" is the proof.** Run the runner against today's
  (unbuilt) code. Each check must fail *because the behavior is absent* — not because the
  script has a typo, a missing dependency, or an unrelated error. A wrong-reason failure
  means the extraction is wrong; fix it. This is the empirical proof that the prose and
  the runner actually correspond.
- **P7 — Two rhythms, one understanding.** Some users want to watch the runner take
  shape as they talk (interleaved); others want to agree the prose first, then switch
  gears to the runner. Both are fine because both rest on P1–P6. Name the choice early,
  then follow the user's lead.
- **P8 — Coordinator, not knowledge holder.** Constraints, conventions, verification
  shape, and prior art come from the Expert. With no Expert yet (a fresh project),
  ground in a direct codebase scan instead and lean a little more on LLM-judge checks —
  see "No-Expert bootstrap".
- **P9 — Transparent, shared understanding.** Explain → confirm → act → take feedback.
  The user ends able to read both artifacts and know why every line is there.

## How to run this skill

You are a guide, not a form. Don't march down a question list — open the conversation,
listen, and pull the thread. Read the two seam references before and during the
conversation so your discipline is grounded, not improvised:

- `references/elicitation.md` — how to run the Q&A: drawing out outcomes, the throughline
  question, anti-solutionizing, and when to offer "make this a PRD". *(Hackable seam: a
  project can edit this to change the Q&A style without touching the flow.)*
- `references/right-reason.md` — what counts as failing for the right reason, with
  examples. *(Hackable seam: the failing-test heuristic lives here.)*
- `references/roadmap-awareness.md` — **optional**: how to ground the PRD's *why* in an
  upstream `/roadmap` **bet or backlog item**, register the PRD back onto it, and the hard
  line that a bet's metric is rationale, never a runner check. The roadmap home is
  self-describing — defer to its `AGENTS.md` for all structure. Only relevant when the user is
  working off a roadmap. *(Hackable seam: how tightly a PRD couples to a bet.)*

And the two artifact references when you reach the build:

- `references/prd-template.md` — the PRD skeleton (minimal by default; optional blocks).
- `references/runner-recipes.md` — the per-check-type cookbook for `run-prd-test.sh`.

## The guided flow

### Step 0 — Preflight
Confirm the working tree is clean; if there's WIP, ask the user to stash or commit first
(this is a "clean your tree" issue, not something to abstract over). Derive the
author-slug from `git config user.email` (the part before `@`). Load the Expert by
reading `.claude/skills/expert/references/*.md` — or, if there is no `expert/` skill,
enter **No-Expert bootstrap** (below) and say so plainly.

### Step 1 — Open Q&A
Understand the need. Elicit outcomes, not solutions (P2). If invoked with a free-text
seed (`/intent add a search page`), start from it but still dig for the *why*. Use the
Expert to ground questions in how this project actually works. Follow
`references/elicitation.md`.

**Optional — roadmap grounding.** Ask whether this feature serves an upstream `/roadmap`
**bet or backlog item**. If so, the user passes the roadmap-home path **inline** (e.g.
`/intent --roadmap ../product-roadmap …`; there is no pointer file). The home is
self-describing: read its `AGENTS.md` for structure, then let the unit's *problem* (and, for a
bet, its *target metric*) sharpen the PRD's `## Why`. A bet's metric is **rationale only —
never a check in `run-prd-test.sh`** (P4): the runner tests *built*, the metric tests *moved*,
and `/evaluate-outcome` owns the latter. After you file the PRD, **register it back** onto the
bet/backlog item per the home's conventions (output tied to outcome). No roadmap → proceed
exactly as normal. See `references/roadmap-awareness.md`.

### Step 2 — Surface external context
Ask whether the user already has anything that should govern this feature: an API
contract / OpenAPI / swagger file, a schema, design mockups, an architecture note,
existing fixtures or golden files. Note what exists and where; you'll route it in Step 5.

### Step 3 — Decide-to-build gate
Only when the intent is clear, offer: "Want me to turn this into a PRD?" Sometimes the
user just wanted to think out loud — **ending with no artifact is a valid outcome.** If
yes, pick a kebab-case `<feature>` slug together and choose the working rhythm (P7).

### Step 4 — Build prd.md + run-prd-test.sh
Build both in the chosen rhythm, driving every desired outcome through "how would we
know that's true?" (P3). Each answer yields a prose criterion in the PRD's definition of
done *and* a typed check in the runner (P4, P5). Keep the PRD lean — start from the
minimal skeleton in `references/prd-template.md` and add optional blocks only when the
conversation surfaces them. Draft the runner using `references/runner-recipes.md`;
**you draft it, the user reviews — never ask the human to hand-author it** (P8).

### Step 5 — Wire Inputs / References
For context from Step 2: copy anything the *runner* needs (contracts, fixtures, golden
files) under `prds/<feature>/` so the runner is self-contained; pure intent/design docs
may be co-located there or linked by repo path. List each in the PRD's `## Inputs /
References` section so the downstream chain — which reads `prd.md` — discovers them.

### Step 6 — Failing-for-the-right-reason loop
`chmod +x prds/<feature>/run-prd-test.sh` and run it against today's code. Read the exit
code and output. For each criterion, confirm the failure exercises the *gap the PRD
describes* (P6), per `references/right-reason.md`. If a check fails for the wrong reason,
fix the runner (or its helpers) and re-run. Iterate until every failure shape matches.
Show the user the output and what it proves.

### Step 7 — Branch, commit, return
With the user's confirmation:
```
git checkout -b prd/<author-slug>/<feature>   # from main
git add prds/<feature>/                        # prd.md, run-prd-test.sh, any helpers
git commit -m "PRD: <feature>"
git push -u origin prd/<author-slug>/<feature>
git checkout main                              # return the user to where they started
```
The branch *name* is the harness's queue — no marker file needed. Tell the user the
harness will pick it up on its next tick.

## Invocation & output contract

- **Invoked by:** a human (`/intent`, optionally with a free-text seed, and optionally
  `--roadmap <path>` to ground the PRD in an upstream bet or backlog item and register the PRD
  back onto it). Not the dispatcher — this is a human-in-the-loop skill.
- **Outputs (relative to repo root):** `prds/<feature>/prd.md`,
  `prds/<feature>/run-prd-test.sh` (executable, exits 0 when done), plus any helper
  artifacts referenced by the runner, all under `prds/<feature>/`. When grounded in a roadmap
  (`--roadmap`), also a register-back commit in the roadmap home (the PRD pointer on its
  bet/backlog item) — per the home's `AGENTS.md`, not auto-pushed.
- **Completion signal for the chain:** the pushed `prd/<author-slug>/<feature>` branch
  carrying those committed files. There is no sentinel file — the branch is the queue.

## Idempotency & re-running
- Re-running `/intent` for a feature whose `prd/<author-slug>/<feature>` branch already
  exists: check out that branch, show the existing artifacts, and amend them rather than
  starting over.
- If a previous run left an uncommitted PRD in the working tree, offer to resume it.

## No-Expert bootstrap
With no `.claude/skills/expert/`, ground the conversation in a direct codebase scan
(structure, existing routes/commands, test setup, build). Constraints come from what you
observe, not from the Expert. Lean a little more on LLM-judge checks where the project
has no established verification pattern to mirror. Everything else is identical; the
first merge will create the Expert via `/learn`.

## Hard nevers
- **Never merge, and never push to `main`.** Humans steer at merge time.
- **Never hand the runner to the human to author.** You draft it from the conversation
  and the Expert's patterns; they review and edit.
- **Never commit a runner you haven't run.** The right-reason loop (Step 6) is required.
- **Never leave the user on a branch other than `main`** at the end.
- **Never bake implementation into the criteria** (P4) — test behavior, not call shapes.
- **Never put a roadmap metric into the runner.** A bet's metric grounds the PRD's *why*
  as rationale; it is measured by `/evaluate-outcome` post-merge, never checked by
  `run-prd-test.sh`. The runner tests *built*, never *moved*.
