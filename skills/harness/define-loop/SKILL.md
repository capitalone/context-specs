---
name: define-loop
description: Guided setup of a NEW intent-sourced namespace loop on top of an already-initialized harness — a minter, a deterministic dispatcher, an oracle, and the passive loops/<ns>/ bundle, all reusing the existing substrate. Use when a developer wants to add, define, create, or scaffold a new autonomous loop (e.g. a bug/, chore/, or vuln/ loop) alongside the prd build loop. Triggers - define-loop, new loop, add a loop, create a namespace loop, scaffold a loop, generalize the harness (project)
---

# define-loop

Stand up a **new intent-sourced namespace loop** on a project that already ran
`/harness-init`, step by step, as a guided expert session. The developer finishes
understanding exactly what was created and why, with every artifact reviewed and
tweakable.

The core idea: **one substrate, many minters.** The harness's control-flow substrate
(claim-by-git-op, per-feature worktrees, write-then-touch sentinels, one-step-per-tick,
bounded-retry→STUCK, forward-only, the non-bypassable oracle — invariants 1–9, factored
into `harness-lib.sh`) is already namespace-agnostic. The `prd` build loop is just its
first instance. A **minter** turns a source-event into a claimable git work-item carrying
an **oracle**; `/intent` is the minter for `prd/`. This skill generates *another* minter +
its loop — differentiated only by the namespace, the minter's PRD template, and the oracle.

> Scope (v1): **intent-sourced** loops only — work that starts from a human/agent-authored
> work-item, like `prd/`. Event-sourced loops (watermark-over-main like `learn`, or
> externally-fed by a scanner/webhook adapter) are a future iteration. This skill does NOT
> modify the `prd` build loop, the `learn` loop, or any pipeline skill — it adds a new loop
> alongside them.

## How to run this skill

You are a guide, not a script runner. For **every** step that writes to disk or runs a git
operation: **explain what you're about to do and why → confirm with the user → do it →
show the result → take feedback and adjust.** You have rich context in `references/`; read
the relevant one before each step and narrate from it in plain language.

Two kinds of artifact:
- **Canonical** (rendered verbatim from `assets/*.template` with the namespace substituted):
  `<ns>-dispatch.sh`, `<ns>-tick.sh`, the `<ns>-loop` shim, the `intent-<ns>` minter, and
  the `loops/<ns>/` bundle. They're the same everywhere except the namespace and the
  interview's phase/oracle choices.
- **Filled-in by the conversation** (Software 3.0): the `## Loop conventions` steering in
  `loops/<ns>/prd-template.md`, the `loops/<ns>/oracle.md` rubric, the phase list, and the
  `loops/<ns>/README.md`. Propose; the user disposes. **Never invent loop behavior the user
  didn't ask for** — ask.

**Substitution.** Every template uses `__NS__` for the namespace. Rendering = read the
`.template`, replace `__NS__` with the chosen namespace, write to the target path, drop the
`.template` suffix. Show the rendered file before writing.

Read first, before talking to the user:
- `references/mental-model.md` — so you can explain one-substrate-many-minters.
- `references/invariants-to-preserve.md` — the rules nothing you generate may break.

Then load other references as each step needs them.

## Preconditions

Runs in the **human's checkout**, on `main`, clean tree, `origin` remote, **and the base
harness already initialized** (`/harness-init` has run: `.harness/env`,
`scripts/poll-and-dispatch.sh`, `scripts/harness-lib.sh` exist). Step 0 verifies this. The
new loop will operate in its own sibling worktrees, never here (Invariant 6).

---

## The guided flow

### Step 0 — Preflight
Run `scripts/preflight.sh <namespace>` from the repo root and walk the report together. It
verifies the base harness is present, that the pipeline skills the loop wires are installed,
that `/intent`'s references exist (the minter clones two of them), and does a re-run /
collision check for this namespace.
- `[MISS]` on the base harness → stop; run `/harness-init` first.
- `[MISS]` on a pipeline skill → note it; the loop dispatches to it the moment it exists.
- `[warn]` on existing `<ns>` artifacts → this is a re-run; diff rather than clobber.

### Step 1 — Namespace + purpose
Agree the kebab-case `<ns>` (e.g. `bug`, `chore`, `vuln`), a one-line statement of what work
this loop processes, and the author-slug (from `git config user.email`). Sanity-check the
name doesn't collide with an existing loop. This `<ns>` is the value substituted for `__NS__`
everywhere and the branch prefix that makes the namespace an explicit, git-native attribute
of every work-item (Inv 2).

### Step 2 — Phases
Read `references/dispatcher-clone-guide.md`. Default to the proven chain (`/spec-planning` →
`/spec-validate` → `/implement-mainspec` → `local-checks` → PR → `/address-feedback`) — it's
the body of `assets/ns-dispatch.sh.template`. Offer to add/remove a phase (e.g. insert a
`/security-review` between validate and implement); each phase is one `elif` + its own
`<step>_CAP` + sentinel. Explain that every reused phase skill is path-based
(`prds/<f>/`, `specs/<f>/`), so it works in a `feature/<ns>/<f>` worktree unchanged — the
minter writes the same `prds/<feature>/` layout.

### Step 3 — Oracle
Read `references/oracle-design.md`. The oracle is **hard, judge-capable, sentinel-cached** —
there is **no soft check** (advisory signal is the reviewer phase). Nail a **hard floor**
first: the baseline `local-checks` gate is auto-wired in the template; confirm at least one
hard check exists so no work-item can pass on vibes. Then shape the LLM-judge layer: fill
`loops/<ns>/oracle.md` (what the judge sees, pass/fail criteria, known-tricky cases). The
per-work-item runner the minter writes is what actually invokes the judge against this
rubric; the dispatcher just runs the runner and caches the green sentinel.

### Step 4 — Minter shaping
Read `references/minter-design.md`. Fill the `## Loop conventions` steering in
`loops/<ns>/prd-template.md` — this is THE place namespace behavior is encoded (there is no
eager namespace memory; the agent learns "how to behave in this loop" from this section +
the phase skills). Decide explicitly **where** the loop's behavioral difference lives
(phase-skill choice vs. PRD-template steering) so the loop can't silently behave like a
plain feature build.

### Step 5 — Generate the artifacts
Render each template (substitute `__NS__`), show it, confirm, write, `chmod +x` the scripts:
- `scripts/<ns>-dispatch.sh`  ← `assets/ns-dispatch.sh.template` (edit the phase block per Step 2)
- `scripts/<ns>-tick.sh`      ← `assets/ns-tick.sh.template`
- `.claude/skills/<ns>-loop/SKILL.md` ← `assets/ns-loop-SKILL.md.template`
- `.claude/skills/intent-<ns>/SKILL.md` ← `assets/intent-ns-SKILL.md.template`, **plus**
  copy `/intent`'s `references/runner-recipes.md` and `references/right-reason.md` into
  `.claude/skills/intent-<ns>/references/` (adapt branch examples to `<ns>/`) so the minter
  is self-contained.
- `loops/<ns>/prd-template.md` ← `assets/prd-template.md.template` (with Step 4 steering)
- `loops/<ns>/oracle.md`       ← `assets/oracle.md.template` (with Step 3 rubric)
- `loops/<ns>/learn-lens.md`   ← `assets/learn-lens.md.template` (passive; unused in v1)
- `loops/<ns>/README.md`       ← `assets/loop-README.md.template`

The dispatcher carries its own copies of `signal_stuck`/`signal_human_review`/
`reviewer_converged`/`has_prd` (they're dispatcher-local in `poll-and-dispatch.sh`); leaving
them in keeps the build loop untouched. `harness-lib.sh` is reused as-is, not copied.

### Step 6 — Commit (then we can provision)
Commit the new files on `main` (or a setup branch the user merges — ask). **This must happen
before Step 7**: the loop's infra worktree is a detached checkout of `origin/main`, so it
only contains the new scripts once they're on `origin/main`. Add the runtime worktrees to
`.gitignore` guidance if the project ignores sibling worktrees.

### Step 7 — Provision the loop's infra worktree
Explain the topology (`references/mental-model.md`): this intent-loop spawns *per-feature*
worktrees like the build loop, so it gets its **own** dedicated infra worktree — separate
from the build host — to avoid racing the build loop's per-tick host sync. Create it
detached at `origin/main` and bootstrap it:
```
git worktree add --detach ../<repo>-harness-ns-<ns> origin/main
( cd ../<repo>-harness-ns-<ns> && [ -x scripts/bootstrap-worktree.sh ] && ./scripts/bootstrap-worktree.sh . || true )
```
The `-ns-` infix keeps this clear of any build-loop feature named `<ns>`
(`../<repo>-harness-<ns>`).

### Step 8 — Verify the loop works
Read `references/verify-the-loop.md` and run the planted-event dry-run with the user:
1. **No work-items** → `./scripts/<ns>-tick.sh` from the infra worktree → clean no-op
   (proves sync + dispatch wiring).
2. **Mint a synthetic item** → `/intent-<ns>` a throwaway work-item → confirm the
   `<ns>/<slug>/<f>` branch pushed and the runner **fails for the right reason**.
3. **Tick to green** → tick repeatedly; confirm claim → `feature/<ns>/<f>` → plan → validate
   → implement → oracle **red**; force the behavior present → oracle **green → sentinel
   cached → PR opens**.
4. **Force STUCK** → drive a step to its cap; confirm the diagnosis-first PR comment + the
   session trail post, and that convergence (`REVIEW_CLEAN_MARKER`) hands off to HUMAN_REVIEW.

If anything errors, debug before starting the loop. (`bash -n scripts/<ns>-dispatch.sh` is a
fast syntax sanity check.)

### Step 9 — Start the loop
The new loop runs as its **own** long-lived `/loop` session, independent of the build and
memory loops:
```
cd ../<repo>-harness-ns-<ns>
claude
/loop 5m /<ns>-loop
```
Recap the daily flow: `/intent-<ns>` in their normal checkout → confirm a work-item → walk
away → the loop runs the chain → on reviewer convergence, `/evaluate-pr <feature>` → merge;
on STUCK, fix the **context defect first**, then the code, then merge.

---

## Re-running
Safe to re-run for the same `<ns>`. Preflight flags existing artifacts. Diff and offer to
update rendered files rather than clobbering. Never delete the loop's infra worktree or
in-flight feature worktrees on a re-run.

## Hard rules (from invariants-to-preserve.md)
- Never run a dispatch loop in the human's checkout (Inv 6).
- Never put an LLM call in the dispatcher's decision path (Inv 5).
- Never replace the atomic-rename claim with a marker/lock file (Inv 2/7).
- Never generate a "go backward" / sentinel-deleting step (Inv 9).
- Never give a loop zero hard gates — the oracle is hard (Inv 8).
- Never modify the `prd` build loop, the `learn` loop, or a shared pipeline skill — add
  alongside, isolated by namespace.
