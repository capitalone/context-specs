---
name: env-init
description: One-time setup of a project as a harness ENVIRONMENT — the Software 3.0 half that follows `context-specs add`. Generates the project-specific artifacts an LLM must read the repo to write (AGENTS.md, bootstrap-worktree.sh, local-checks.sh), installs the project-owned /intent, seeds the Expert (long-term memory) skeleton, wires the reviewer, and gathers it all onto a feature/env-init PR. Use when a developer wants to set up, initialize, or onboard a project/environment for the coding harness.
---

# env-init

Stand up a project as a harness **environment**. You are an autonomous
installer: you write the artifacts end-to-end, explain the *significance* of
each as you go, and gather everything onto a `feature/env-init` PR the human
reviews and merges.

You are the second half of a two-command setup, and the split is the point —
it is harness engineering in miniature:

- **`context-specs add <path>` already ran** (deterministic CLI, tier 1): it
  registered this environment with the harness repo, symlinked the canonical
  skills/agents into `.claude/` (gitignored), and wrote the managed `.gitignore`
  block. Everything a script can do without reading the project, a script did.
- **You do what needs judgment** (Software 3.0, tier 2): every artifact below
  requires *reading this project* — its manifests, README, CI, conventions.
  Scan, generate, cite the evidence. **Never invent a command you didn't see
  evidence for** — ask instead.

The tier test, if you're ever unsure what belongs to you: *could this be
written without reading the project's code?* Yes → it's the CLI's/harness
repo's, leave it alone. No → it's yours to generate here.

## Operating mode

Run the steps end-to-end without stopping for per-step approval — **the user
reviews everything in the `feature/env-init` PR.** Your job while installing is
to explain *significance*: for each artifact, one or two sentences on what it
is, why it exists, and what would break without it. Lead with the why, then
write the file.

Read first: `references/mental-model.md` (so you can explain what the harness
*is*) and `references/invariants-to-preserve.md` (the rules nothing you
generate may break). Load other references as each step needs them.

**Stop-and-confirm points — the only interruptions:**

1. **Secret-copying** (bootstrap step) — before writing any `cp` line that
   touches a `.env` or credentials file: name the exact files, confirm copy
   direction (source → worktree, never reverse, never delete), get explicit consent.
2. **Reviewer choice** — wires CI and billing; the user's call.
3. **The PR merge** — after the PR opens, stop and wait for the human.

## Preconditions

- Run in the **developer's checkout** of the environment, on `main`, clean tree,
  `origin` remote.
- `context-specs add` has run: `.claude/skills/` contains symlinks into the
  harness repo (you are reading this SKILL.md through one). If it hasn't,
  stop and have the user run it first; `context-specs doctor` diagnoses.

---

## The install chain

### Step 1 — Config (`.harness/env`)

Read `references/config-options.md`. Write `.harness/env` from
`assets/harness-env.template` with the defaults (`MAX_WORKTREES=1`, per-dev
`WATCH_PATTERN` derived from `git config user.email`) unless the user has a
concrete reason otherwise. This file is **committed** — it is the environment's
project-owned dial on the tier-1 dispatcher. Runtime counters live in the
harness repo's `state/<env>/`, so there is nothing to gitignore here.

### Step 2 — Install `/intent` (project-owned, one of the two levers)

`/intent` is deliberately **not** symlinked like the other skills — it is a
committed, project-owned artifact, because *how well this project expresses
intent is one of the biggest levers it has*. Frame it exactly that way to the
user: **/intent and the Expert are the two developer-owned levers** — /intent
shapes what goes *into* every feature (the PRD + runnable definition of done),
the Expert shapes what every feature *knows*. Developers should expect to tune
both over time.

Copy the canonical template from the harness repo:
`$CONTEXT_SPECS_HOME/skills/human-loop/intent/` → `.claude/skills/intent/`
(SKILL.md + references/). (`CONTEXT_SPECS_HOME` = the symlinks' target root:
`readlink .claude/skills/spec-planning` and strip `/skills/...`.) Then offer
the choice:

- **Generic (fine to start):** install verbatim; customize later by editing —
  it's the project's file either way.
- **Customized now:** scan the repo and tailor the marked hackable seams —
  `references/prd-template.md` (project DoD conventions: what can
  `run-prd-test.sh` actually exercise here — e2e harness? LLM-judge hybrid?),
  `references/elicitation.md` (domain vocabulary, the questions this project's
  features always end up needing), `references/runner-recipes.md` (this
  project's test idioms). Cite the scan evidence for every tailored line.

### Step 3 — Seed the Expert (long-term memory) skeleton

Copy `assets/expert-skeleton/` → `.claude/skills/expert/`. Structure only —
empty routing table, no invented content: shards are added by `/learn` (post-
merge), by the implementer's Reflect step (post-slice), **and by the developer
directly**.

Narrate the ownership model loudly; it is the heart of the system: the Expert
is the project's long-term memory, and **the developer owns it**. The loops
are continuous helpers that file things into it; editing it directly is
expected, not exceptional. Long-term memory informs short-term memory — every
`/spec-planning` run reads this to plan the next feature — so improving a shard
improves every future feature. The skeleton's conventions (one topic per shard,
prefix names, `USE WHEN:` openers, routing table inline in SKILL.md) exist so a
weak plan can be traced back to the specific shard that should have taught it.

### Step 4 — `AGENTS.md` (Software 3.0)

Read `references/agents-md-guidance.md` and `references/project-discovery.md`.
Scan the repo, fill `assets/AGENTS.md.template`'s bracketed parts (project name,
the verification-layer tooling), keep the rest verbatim. AGENTS.md is the
neutral, eagerly-loaded contract — a map that points into the Expert, not an
encyclopedia; keep it tight (~150 lines). Cite the scan finding behind each
filled-in line. The Expert section is intentional even while the Expert is a
skeleton.

### Step 5 — `scripts/local-checks.sh` (optional, Software 3.0)

The deterministic gate the dispatcher runs before opening a PR (two-strike:
`local-checks.sh fix` → `/fix-local-checks` → STUCK). Cheapest place to catch
correctness issues — left of the reviewer and CI. **Read
`references/local-checks-design.md` first** and narrate the *why*; the user
owns and tunes this script. Two responsibilities:

- **Wire the project's deterministic checks** — lint/format (with a `fix`
  subcommand), typecheck, the **fast** unit suite (slow/integration → CI), a
  **skip-detection** check, and everything in `scripts/lints/`. Prefer commands
  the project already defines.
- **Propose custom correctness lints** from the codebase as-is (snapshot
  discovery), behind the five guards in the reference.

The gate proves **correctness, not coverage** — block only
correctness/structural, warn on legibility. The **skip rule** is load-bearing:
an agent may never add a test-skip marker; a legitimate skip is the human's
call at STUCK. If the project has no deterministic checks, skip this step —
the dispatcher treats the script as absent and works fine.

### Step 6 — `scripts/bootstrap-worktree.sh` (Software 3.0 below the line)

Read `references/worktree-bootstrap.md`. Generate from
`assets/bootstrap-worktree.template.sh`, whose **deterministic header is
verbatim and untouchable**: it calls `context-specs link` so every fresh
worktree gets the tier-1 skill symlinks (gitignored symlinks never materialize
in new worktrees — without this line, every headless step would run skill-less).
The dispatcher exports `CONTEXT_SPECS_HOME` when it calls this script, so
nothing machine-specific is committed.

You generate only the section **below the marker**: copy gitignored runtime
files, install dependencies, run codegen — discovered from
README/CI/manifests (`references/project-discovery.md`); if discovery is thin,
ask the user how they set the project up on a fresh machine. Idempotent,
non-interactive, well-commented.

**The secret-copy lines are stop-and-confirm point 1** — see Operating mode.
If the project has no gitignored secrets, skip that part and say so.

### Step 7 — Reviewer (stop-and-confirm point 2)

Read `references/reviewer-options.md`. Three paths (self-hosted via
`claude-code-action` = recommended default; managed Code Review; none);
switching later is cheap. **Present the paths, recommend self-hosted, and
confirm — including auth — before configuring anything.**

- **Self-hosted:** copy `assets/REVIEW.md` → repo root and
  `assets/workflows/claude-review.yml` → `.github/workflows/`, then:
  1. **Pick auth with the user:** subscription (`CLAUDE_CODE_OAUTH_TOKEN` from
     `claude setup-token`) vs metered API (`ANTHROPIC_API_KEY`). Uncomment the
     chosen line, have them add the matching repo secret.
  2. **Pin the action** to the current release tag
     (`gh release view --repo anthropics/claude-code-action`).
  3. **Tell them the v1 same-content rule:** the workflow only takes effect
     once merged to `main`; it can't be tested from a feature branch.
- **Managed:** copy `REVIEW.md`; give the GitHub App install instructions.
- **None:** create nothing; set `REVIEW_CLEAN_MARKER=` (empty) in
  `.harness/env` so the dispatcher converges at PR-open.

**Convergence marker (both reviewer paths):** `REVIEW.md` instructs the
reviewer to post a PR comment containing `HARNESS_REVIEW_CLEAN` once no
Important findings remain; the dispatcher sees it and hands the PR to the human
for `/evaluate-pr`. Configurable via `REVIEW_CLEAN_MARKER` (must match
REVIEW.md). If the reviewer never posts it, the feedback loop STUCKs at
`FEEDBACK_CAP` instead — a clean PR the human merges.

### Step 8 — Commit on `feature/env-init`, push, open PR, wait for merge

**Hard rule: never commit setup artifacts directly to `main`.** Everything from
Steps 1–7 — plus the `.gitignore` block `context-specs add` wrote — lands on
`feature/env-init` and reaches `main` only via a merged PR: the whole install
in one reviewable diff.

```
git checkout -b feature/env-init
git add .harness/env .gitignore scripts/ AGENTS.md REVIEW.md .github/ \
        .claude/skills/intent .claude/skills/expert
git commit -m "harness: environment setup via env-init"
git push -u origin feature/env-init
gh pr create --base main --head feature/env-init \
             --title "harness: environment setup" --fill
```

(The symlinked skills are gitignored and stay out of the diff — that's the
tier split showing up in git: canonical stays in the harness repo, project-owned
gets committed here.)

Walk the user through the PR, then **stop and ask them to merge before
continuing (stop-and-confirm point 3).** Why merge first: the dispatcher works
entirely through `origin` — it claims PRDs from origin refs and creates
worktrees from `origin/feature/*` branches that fork off `main`. Until this
merge lands, those branches would contain none of these artifacts (no
`.harness/env`, no bootstrap, no Expert), so the first feature would run
against an unconfigured project.

### Step 9 — Prove the wiring, then hand off to the CLI

Once merged (`git fetch && git pull`), have the user run, from the harness repo:

```
context-specs doctor        # every check green for this environment
context-specs run <env>     # one foreground tick: fetch, find nothing, exit idle
```

A clean no-op `run` proves the whole chain — registry, dispatcher, config,
worktree base — without doing any work. Then the daily flow:

```
context-specs start <env>   # background supervisor: build loop + memory loop
```

1. **`/intent`** in this checkout → confirm a PRD → walk away. The harness
   picks it up (a tick that advances work re-fires immediately — real work
   drains at machine speed; idle ticks nap the interval).
2. Either: the reviewer converges → the harness posts **"Ready for your
   review"** with the build-session trail → run **`/evaluate-pr <feature>`**,
   understand it, merge. Or: a step hits its cap → **STUCK** post with the
   session log + diagnosis-first checklist. **Your first job is the context
   defect, not the code** — find which AGENTS.md / Expert / spec / PRD content
   misled the agent, correct it on the branch, then fix the code, merge.
3. After each merge, the memory loop raises a `learn/<sha>` PR — the project
   updating its own long-term memory. Review it with the same care as code:
   it decides what every future feature knows.

`context-specs status` shows every environment's features and phases;
`context-specs logs <env> -f` follows the loop.

---

## Inner skill dependency

The dispatcher invokes `/spec-planning`, `/spec-validate`, `/implement-mainspec`,
`/fix-local-checks`, and `/address-feedback`; the memory loop invokes `/learn`.
All arrive as symlinks from the harness repo via `context-specs add` — verify
they resolve (`context-specs doctor`). Two are **human-invoked**: `/intent`
(installed by Step 2 as project-owned) and `/evaluate-pr`. env-init generates
the project-specific artifacts; it does not author skills.

## Re-running

Safe to re-run. For canonical files (REVIEW.md, workflow, the bootstrap
header), diff and offer to update. For generated files (`AGENTS.md`,
`local-checks.sh`, the bootstrap body, /intent customizations), re-scan and
show a diff rather than overwriting blind. Never overwrite the Expert's
references/ — that is live memory now, not yours. If `feature/env-init`
already exists from a prior run, update that branch rather than creating a
fresh one.

## Hard rules (from invariants-to-preserve.md)

- Never generate an LLM call into the dispatcher's decision path (Invariant 5).
- Never replace the atomic-rename claim with a marker/lock file (Invariant 2/7).
- Never generate a "go backward" / sentinel-deleting step (Invariant 9).
- `bootstrap-worktree.sh` copies secrets source→worktree only, never deletes,
  never the reverse (Invariant 6) — and its `context-specs link` header stays.
- Never commit setup artifacts directly to `main` — everything rides the
  `feature/env-init` PR (Step 8).
