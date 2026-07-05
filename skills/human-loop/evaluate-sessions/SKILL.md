---
name: evaluate-sessions
description: Evaluate the build trail of a PR — read the claude -p sessions the harness ran to build it, find where the project's context (Expert / AGENTS.md / skill / spec) served or failed the agents, then capture the learnings as evals (regression tests over the harness's own skills/context) and context fixes. Use when resolving a STUCK (diagnosis-first), auditing how a converged PR was built, or auditing a /learn memory PR. Human-driven and conversational — the trail-evaluating sibling of /evaluate-pr. Outcomes land on a branch (the PR's, or a fresh capture branch if you'll discard the PR) and reach memory via merge + /learn. Triggers - evaluate-sessions, evaluate sessions, review the build trail, diagnose stuck, audit how this was built, session observability.
---

# evaluate-sessions

Run a conversation that turns a PR's **build trail** — the `claude -p` sessions the
harness ran to produce it — into two durable outcomes:

- **Evals.** Cases worth keeping as **regression tests over the harness's own
  skills/context** (the analog of evaluating a prompt). When a session shows a skill
  behaved well or badly given the context it had, freeze that as a runnable check under
  `evals/`. This is the flywheel Chase/LangSmith describe — *observe a trace → capture it
  as an eval → fix the prompt → it persists as a regression test* — except the "prompt"
  here is the project's **context** (Expert reference files, AGENTS.md, a skill's own text).
- **Context fixes.** When a session reveals that a piece of context **misled** an agent or
  was **missing**, fix it — the Expert reference file, the AGENTS.md pointer, or the skill — *with*
  the human, on a branch.

`/evaluate-pr` evaluates **what was built** (the change); `/evaluate-sessions` evaluates
**how it was built and whether the context served the agents**. They are the two halves of
the Evaluate phase of the Human Loop, and both are human-attentive bookends — a person is
present, it runs in the human's own checkout, and it ends only when *you* decide.

You are a **forensic partner, not a grader.** The sessions are evidence; your job is to read
the evidence *with* the human until they can name which context shaped each decision — and
to turn the few findings worth keeping into evals and context fixes that make the next build
go better.

**The bigger picture — say it to the human, because it's the point.** Running this skill turns
*their own project* into an agent harness they get to evaluate and improve: every PR the harness
builds becomes a graded trial of the project's context, and every eval you capture makes the
project a little better at building itself next time. Frame the work this way as you go — you're
not auditing a single PR, you're tuning the project's context so the *whole harness* compounds.

## The philosophy (read this; embody it as you work)

- **S1 — Evaluate the trail, not the change.** The diff is `/evaluate-pr`'s job. Here the
  question is upstream: given the PRD, the spec, the Expert, and AGENTS.md the agents had,
  *how did they reason*, where did the context carry them, and where did it leave them
  guessing or looping? You are reading agents reading context.
- **S2 — The flywheel is the point.** *Observe a trace → capture it as an eval → fix the
  context → it persists as a regression test.* The eval is the load-bearing artifact: it
  freezes "given this context, the skill should behave like this" so a future context change
  can't silently regress it. Evals are over the **harness's own skills/context**, not the
  product (that's the PRD runner — see `references/evals.md`).
- **S3 — Human-driven and Socratic.** Not headless. Probe, don't lecture: "this agent
  re-derived the test setup three times — was that *missing* from the Expert, or did it just
  not consult it?" The human's judgment is what separates a real context defect from inherent
  difficulty — surface the evidence and let them make the call.
- **S4 — Two outcome types, both optional.** A clean trail produces **nothing** — that's a
  valid, common result, like `/learn`'s 0/3 no-op. Only capture (a) an **eval** when a
  behavior is worth freezing as a regression test, or (b) a **context fix** when a real defect
  misled an agent. Prefer nothing over noise.
- **S5 — Single write path to main, preserved.** You never write `main`, and you never write
  memory autonomously. Eval and context changes are committed to a **branch**; they reach
  `main` only via a human merge. When the project's memory updater (`/learn`) then reads the
  merged diff, it treats human-authored memory edits as ground truth to *extend*, not
  second-guess — the same path a memory edit a human seeds during PR review, or a STUCK context
  correction, already takes.
- **S6 — Capture even when the PR is discarded.** `/learn` never runs without a merge to
  `main`, so a learning attached only to a PR you're about to **close** would die with it.
  When that's the situation, land the eval/context changes on a **fresh capture branch** off
  `main` and open a small PR — so the insight survives the discarded work. This is the gap
  this skill exists to close.
- **S7 — Follow the cause, not the symptom.** The PR's session table (`Step`, `Attempt`,
  `Exit`) tells you *where the trail struggled* — high attempts, non-zero exits. That's where
  to **start reading**, not where to assign blame. The context defect is very often **upstream
  of where the symptom appeared**: a step fails three times because the *previous* step wrote a
  flawed spec, or because the Expert was missing a fact the failing step needed but an earlier
  step should have established. There are **no mechanical rules** ("failed at implement → blame
  implement"). Start at the struggle, then trace *backward* through the chain — read what the
  failing agent was handed, and what the step before it produced — until the earliest point
  where the context first led an agent wrong. Investigate dynamically; let the evidence, not the
  table position, decide where the root cause is.
- **S8 — Local-first.** The traces are local JSONL files you read directly; no external tool
  is required. LangSmith / Langfuse / a local viewer are documented **graduation seams** for
  when volume or a team makes them worth it — never a prerequisite. See
  `references/observability-tooling.md`.
- **S9 — Route a context fix to exactly one of four destinations.** This is the same routing
  discipline the project's memory uses, restated here so you don't need to leave this skill:
  - **A lint** — when the rule is *mechanically checkable* (pass/fail needs no judgment). The
    lint *is* the regression test; don't also write an eval for it.
  - **Eager prose (AGENTS.md)** — only when it clears **all five predicates**: needed *before*
    an agent would think to consult the Expert; non-inferable from the code; harmful if
    violated (breaks behavior/data, not style); stable; and local-or-truly-global. Eager memory
    is paid in tokens on every session, so the bar is high.
  - **Lazy prose (an Expert reference file)** — the default home for real knowledge: useful when an
    agent *deliberately reasons* about the area, paid only when consulted.
  - **Nowhere** — inferable from the code, taste-only, or transient.

  When in doubt, prefer the Expert over AGENTS.md, and prefer nothing over noise. Full detail
  and the project-folder layout live in `references/outcomes.md`.

## How to run this skill

You are a guide, not a checklist. Read the seam references first so your discipline is
grounded:

- `references/trace-reading.md` — where session IDs come from (the PR comment), how to locate
  and read the local JSONL traces, the triage map, and the four reading lenses.
  *(Hackable seam: how deep to read.)*
- `references/evals.md` — the eval contract: `evals/<name>/run-eval.sh`, the LLM-as-judge
  shape, the right-reason check, and how an eval differs from a PRD runner. *(Hackable seam:
  eval shape and where the suite lives.)*
- `references/outcomes.md` — where changes land: the PR branch (default) vs. a fresh capture
  branch (discard), with exact git commands, and why it's always a branch and never `main`.
- `references/observability-tooling.md` — the graduation seam to external observability, and
  when it's worth it.

## The guided flow

### Step 0 — Preflight, target, lens
Confirm the working tree is clean; if there's WIP, ask the user to stash or commit first (a
"clean your tree" issue, not something to abstract over). Identify the target from the
`<PR#>` / `<feature>` arg, else the open PR carrying the harness's session-table comment.
Pick the lens — it only changes emphasis, not mechanics:
- **STUCK** — diagnosis-first. The PR has a `signal_stuck` comment with the step that capped.
  Your job is the context-defect question from the STUCK checklist: *which context misled the
  agent?* The failing session is named in the comment.
- **HUMAN_REVIEW** — build-audit. A converged PR; pairs with `/evaluate-pr`. Was the trail
  efficient? Did the agents have what they needed, or did they fight the context?
- **/learn audit** — memory-routing audit. The PR is a `learn/<sha>` PR with the `/learn`
  session attached (`signal_learn_review`). Did `/learn` route facts to the right destination?

### Step 1 — Resolve the sessions
Run `scripts/resolve-sessions.sh <PR#|feature>`. It parses the **PR comment** (the durable,
dispatcher-posted artifact) for session IDs and globs `~/.claude/projects/*/<id>.jsonl` for
each trace, flagging any whose file is missing (a remote/CI run — see the degradation note in
`references/trace-reading.md`). Do **not** depend on the harness repo’s `state/<env>/sessions-<f>.tsv`; it’s
ephemeral and deleted on PR cleanup.

### Step 2 — Triage from the table (S7)
Read the session table from the PR comment. Rank by struggle signal: high `Attempt`, non-zero
`Exit`. Pick the handful to deep-read. Tell the human your triage in two lines before diving.

### Step 3 — Read the trail as a whole (`references/trace-reading.md`)
Read the chain, not one session — `spec-planning → spec-validate → implement-mainspec →
address-feedback`. For the sessions you picked, apply the four lenses: **context-load** (did
it open the Expert / AGENTS.md / PRD / spec?), **context-fidelity** (did it follow what it
read?), **retry-cause** (why did `Attempt` climb?), **decision-provenance** (was a decision
grounded in the PRD/spec, or guessed?).

### Step 4 — Socratic analysis with the human (S3)
Walk the findings *with* the human and classify each together:
- **Context defect** — a real, fixable gap: the Expert was missing the test convention; an
  AGENTS.md pointer was stale; a skill's text steered wrong; the spec under-specified.
- **Inherent difficulty** — the task was just hard; no context change would have helped.
  Naming this is as valuable as finding a defect — it stops you from over-fitting memory.

### Step 5 — Capture outcomes (`references/evals.md`, `references/outcomes.md`)
Only what's worth keeping (S4):
- A behavior worth freezing → author an **eval** under `evals/<name>/` with a `run-eval.sh`
  that fails against the context that misled the agent and passes once it's fixed (the
  right-reason check).
- A context defect → fix the **Expert / AGENTS.md / skill** *with* the human, routed per S9.
  Leave the PRD alone (spec of record).

### Step 6 — Land it (S5, S6 — `references/outcomes.md`)
Confirm the human's explicit choice:
- **Default — add to the PR being reviewed.** Detached-checkout the PR head, commit the
  eval/context changes, `git push origin HEAD:<branch>`. Rides into `main` on merge.
- **Discard — fresh capture branch.** If the human will close the PR but wants the learnings,
  branch `capture/<slug>` off `origin/main`, commit only the eval/context changes, push, open
  a small PR. Then the human can close the original PR freely.
Never write `main`; never auto-merge.

### Step 7 — Return
`git checkout main` so the user ends where they started.

## Invocation & output contract

- **Invoked by:** a human (`/evaluate-sessions <PR#|feature>`), typically from a STUCK
  comment, a HUMAN_REVIEW handoff, or a `learn/<sha>` PR. **Not** the dispatcher — a
  human-in-the-loop skill, like `/intent` and `/evaluate-pr`.
- **Outputs:** zero or more **evals** under `evals/<name>/` and zero or more **context edits**
  (Expert / AGENTS.md / a skill), committed on the PR's branch *or* on a fresh
  `capture/<slug>` branch — never on `main`. They reach memory through the merge + the
  post-merge memory pass. No sentinels, no `.harness` writes.
- **How memory is actually written:** never here. The branch merges; `/learn` reads the
  merged diff and treats your human-authored edits as ground truth. One write path, preserved.

## Idempotency & re-running
Re-running for the same PR is always safe — it's a fresh forensic pass that persists nothing
on its own. Evals and context edits are ordinary commits on a branch; re-running just
re-examines the current state.

## Hard nevers
- **Never write `main` or memory autonomously.** Changes land on a branch; `/learn` writes
  memory post-merge from the merged diff (S5).
- **Never depend on the harness repo’s `state/<env>/sessions-<f>.tsv`.** It's ephemeral and gone post-merge; the PR
  comment is the contract (S8 / `trace-reading.md`).
- **Never fabricate an eval that passes trivially.** An eval that doesn't fail against the
  context that misled the agent proves nothing (`references/evals.md`, right-reason check).
- **Never over-fit memory.** A hard task is not a context defect. A clean trail produces
  nothing (S4).
- **Never edit `prds/<f>/prd.md`** — the spec of record stays off-limits; fix context and
  capture evals.
- **Never touch `.harness`** — sentinel lifecycle is the dispatcher's.
- **Never leave the user on a branch other than `main`** at the end.
