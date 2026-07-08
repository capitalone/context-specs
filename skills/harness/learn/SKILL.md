---
name: learn
description: Update the project's long-term memory after a merge to main. Reads the merged diff and reconciles the current memory — adding, editing, and deleting Expert reference files — then drafts candidate lints and AGENTS.md pointers. Opens a reviewable learn/<sha> PR, or prints "nothing to learn" and exits if the merge produced no material change. Use post-merge (the harness invokes it automatically) or with --rebuild to regenerate memory from scratch. Triggers - learn, expert-update, update memory, update expert, post-merge memory, self-improve (project)
---

# learn

This is how the project **gets better on every merge.** When code lands on main,
`/learn` reconciles the project's long-term memory with what just landed: it
updates the **Expert** (procedural + semantic memory, pulled on demand) and the
**AGENTS.md** map (eager memory, loaded as agents traverse the repo), discovers
project invariants, and drafts candidate **lints** (the highest-value memory,
because a lint is a rule the agent cannot ship past).

You run **headless**, invoked by the **memory loop** (`scripts/learn-dispatch.sh` in the harness repo, driven
by the `context-specs` supervisor on its own interval) as the post-merge step — in a dedicated
`../<repo>-harness-learn` worktree on a `learn/<sha>` branch off `origin/main`, never
in the developer's clone. The memory loop runs independently of the
feature/build loop, so a from-scratch Expert bootstrap blocks neither. Your output is
a single reviewable PR — never an auto-merge. Humans steer at merge.

## What memory is (read this first)

> **The memory is the developer's.** It holds facts about the code as it is *and*
> decisions, direction, and aspirations the developer has written that the code
> hasn't caught up to. **Your input is the merged diff** — that's why you run
> post-merge — and your job is to reconcile memory with it: add what the merge
> taught, update what it invalidated, and *advance* any direction it touches
> (fulfilled → rewrite as cited fact; contradicted → edit and note it). Direction
> is never stale merely because it isn't observable in code yet.

You are the *automated* writer; the developer writes memory directly, any time,
and their edits are authoritative (P7). STUCK features are handled by the human
directly (their first job there is to identify the context defect that misled the
agent, correct it on the feature branch, then fix the code); their corrections
ride into main with the feature merge, and **you observe them in the diff you
read**.

## The philosophy

- **P1 — Write from the merged diff.** Your own additions are evidence-based:
  cite the diff. But memory as a whole is not diff-shaped — developer-written
  direction lives beside your facts, and you maintain it (advance or close it
  when a merge fulfills or contradicts it), never delete it for lacking a code
  anchor.
- **P2 — Two memory shapes, opposite costs.** The **Expert** is *pulled on demand*
  (cheap until consulted). **AGENTS.md** is *eager* — loaded automatically every
  session that touches a folder, paid in tokens whether or not it's relevant. So
  the bar for putting something in AGENTS.md is **far higher** than for the Expert.
- **P3 — The four destinations.** Every fact worth remembering routes to exactly
  one place: a **lint** (if mechanically checkable), **eager prose** (AGENTS.md, if
  it clears the high bar), **lazy prose** (an Expert reference file — one of
  `how-to-*` / `concept-*` / `pattern-*` / `invariant-*` / `example-*` /
  `decision-*`), or **nowhere**. Most things go nowhere or to the Expert. The
  `decision-*` prefix is forward-looking direction — human-authored, never one you
  seed; you only *retire* it when a merge fulfills or reverses it (P9). See
  `references/routing-rules.md` and `references/expert-structure.md`.
- **P4 — Map, not encyclopedia.** AGENTS.md is the table of contents that *points
  into* the Expert; it never duplicates it. A monolithic AGENTS.md rots, crowds
  out the task, and turns "everything important" into "nothing important." Keep it
  a map. See `references/agents-md-guidance.md`.
- **P5 — Progressive disclosure inside the Expert.** Reference files are small and
  topic-focused, cross-linked via Obsidian `[[wikilinks]]`. SKILL.md is an index —
  one line per file. An agent reads the index, opens only what's relevant, then
  follows wikilinks to discover related context. See
  `references/expert-structure.md` and `references/wikilink-convention.md`.
- **P6 — Invariants are discovered, then promoted.** You may notice architectural
  rules the codebase upholds. Record each as its own `invariant-<rule>.md` file
  (one rule per file); flag the mechanically checkable ones as candidate **lints**
  (the highest-value memory, because a lint is a rule the agent *cannot* ship
  past). See `references/invariant-discovery.md`.
- **P7 — Human-authored memory edits are authoritative.** When the merged diff
  *already* touches AGENTS.md, an Expert reference file, or a spec, treat those
  changes as **authoritative — extend them, never second-guess them.** They came
  from a human resolving a STUCK or making a deliberate correction. Your job there
  is to *extend* (what else, given this correction, now needs to change?) — not to
  vote on whether to apply it.
- **P8 — Reviewable, revertible, human-merged.** Everything lands on a `learn/<sha>`
  PR. Never auto-merge.
- **P9 — Reconcile, don't accumulate.** Memory is a *current model of the
  project* — its code and its intent — not
  an append-only log. Every run must look for deleted concepts (the code is gone →
  the reference file goes), inter-file contradictions (two files disagree → merge
  or scope-qualify), and claims invalidated by the merged diff. **Adds, edits, and
  deletes** all ride on the same PR. See `references/reconcile.md`.
- **P10 — Nothing to learn is a valid outcome.** Most merges produce nothing for
  memory. When `reconcile` finds zero adds, edits, deletes, AGENTS.md pointer
  changes, or candidate lints, print `learn: nothing to learn from <sha>, skipping
  PR` to stdout, exit 0, and do not push a branch or open a PR. The outer loop
  advances `refs/harness/last-learned` regardless.

## How to run this skill

Read the seam references before acting; they are the hackable contract a project
tunes to its taste:

- `references/routing-rules.md` — the four destinations + the five-predicate test
  for eager placement + the six sub-destinations for the Expert + the line-count
  caps. *(Primary hackable seam.)*
- `references/expert-structure.md` — the flat prefix-named layout, the five
  prefixes, the SKILL.md index, the bootstrap seed list.
- `references/wikilink-convention.md` — the `[[basename]]` cross-link syntax used
  inside `expert/references/` and the lint that enforces it.
- `references/reconcile.md` — the three-pass add/edit/delete logic plus the
  nothing-to-learn early exit.
- `references/agents-md-guidance.md` — map-not-manual; which folders earn a nested
  AGENTS.md; the freshness contract.
- `references/invariant-discovery.md` — how to surface invariants and draft lints
  without overfitting.

## The flow

### Step 0 — Mode + idempotency
Determine mode:
- **Bootstrap** — `.claude/skills/expert/` is empty (no `SKILL.md` index inside),
  or `--rebuild` was passed: create the Expert from scratch by scanning committed
  code, seed the minimum-viable file set (see `references/expert-structure.md`)
  + the root `AGENTS.md`. This is also the recovery path. Check for the presence
  of `SKILL.md` inside the dir, not for the dir itself.
- **Incremental** — the Expert exists (contains a `SKILL.md`): reconcile against the merged diff.

Idempotency: if `learn/<sha>` already exists on origin, another node handled this
merge — exit cleanly. (The memory loop pre-checks this too, via `git ls-remote`.)

### Step 1 — Gather
Read: the diff for `--since <sha>..--sha <sha>`; the current Expert reference
files (`ls .claude/skills/expert/references/*.md` plus their contents); the
AGENTS.md files the diff touches (root + any in changed folders); and the
PRD(s)/spec(s) for the merged feature if present (`prds/<f>/`, `specs/<f>/`) for
the *why*.

**Notice whether the diff itself touches memory files** (AGENTS.md, Expert
reference files, spec sections). If so, you're looking at a human's context
correction — see P7; those changes are authoritative.

### Step 2 — Reconcile
Run the three-pass reconcile (`references/reconcile.md`) in the main agent — no
subagent fanout. Produce three candidate lists: `adds[]`, `edits[]`, `deletes[]`.
Every candidate carries a **one-line justification** citing the diff hunk
(file:line range) or the contradicting reference file. If you can't write the
justification, drop the candidate.

The three passes:
1. **Deleted-concept** — references whose anchor code is gone → `delete`.
2. **Inter-file contradiction** — pairs that disagree → rewrite both to
   scope-qualify, merge them, or drop the stale one.
3. **Diff-invalidates-file** — references contradicted by the merge → `edit`.

### Step 3 — Route
For each surviving candidate, apply `references/routing-rules.md`: lint /
eager AGENTS.md / lazy Expert reference (then pick the prefix: `how-to-*` /
`concept-*` / `pattern-*` / `invariant-*` / `example-*`) / nowhere. When in
doubt, prefer the Expert (cheap) over AGENTS.md (eager), and prefer *nothing*
over noise.

### Step 3.5 — Nothing-to-learn check
If after Reconcile + Route the totals are empty:

```
len(adds) + len(edits) + len(deletes) == 0
AND no AGENTS.md pointer change
AND no candidate lint
```

…print `learn: nothing to learn from <sha>, skipping PR` to stdout, exit 0.
Do **not** push a branch, do **not** open a PR, do **not** commit. The outer
loop advances `refs/harness/last-learned` regardless.

### Step 4 — Write
- **Expert references** — apply adds/edits/deletes to
  `.claude/skills/expert/references/`. New files use the prefix layout
  (`how-to-<verb-noun>.md`, `concept-<topic>.md`, etc.). Cross-link to related
  files with `[[wikilinks]]` (no path, no extension). Update
  `.claude/skills/expert/SKILL.md`'s one-line-per-file index to match the new set.
- **Fulfilled decisions** — when the merged diff **realizes** a `decision-*`
  shard (the code now matches the direction it stated), *promote and retire*:
  fold its now-true content into the matching `concept-*`/`pattern-*` fact shard
  (add or edit), then **delete the `decision-*` file**. If the diff instead
  **reverses** a decision, delete it. Both carry a one-line PR-body justification
  citing the diff hunk (e.g. "PR realized event-sourcing → promoted to
  `concept-ledger-architecture`, deleted `decision-event-source-the-ledger`").
  A decision the diff neither fulfills nor reverses is **left untouched** — you
  never seed, edit, or delete a live decision on your own initiative.
- **Invariants** — each discovered hard rule lands as its own
  `invariant-<rule>.md` (one rule per file). For mechanically checkable ones,
  draft a candidate lint (code + remediation-message-as-prompt) under
  `scripts/lints/` and wire it into `scripts/local-checks.sh`. **The drafted
  lint MUST pass against the just-merged code before you include it** — run it;
  if it fails on current main it's wrong.
- **AGENTS.md** — update the relevant map's pointer(s). Propose a *new* nested
  AGENTS.md only when the merge introduced a folder-local rule that clears the
  five-predicate bar and no file exists. Stay under the caps. AGENTS.md uses
  regular `[text](path)` markdown links — **not** wikilinks.

### Step 5 — Validate
Run `scripts/check-agents-md.sh` (AGENTS.md pointers exist, cross-links resolve,
under caps) and `scripts/check-expert-links.sh` (every `[[wikilink]]` resolves
to a file in `expert/references/`). Re-run any drafted lint against current
main (must pass).

### Step 6 — Open PR
Commit the changes and open the `learn/<sha>` PR. The PR body lists every
add/edit/delete with its one-line justification. **No changelog file is
appended** — the git history of `learn/<sha>` PRs is the changelog.

## Invocation & output contract
- **Invoked by:** the memory loop, `claude -p "/learn --since <sha> --sha <sha>"`,
  inside the `../<repo>-harness-learn` worktree. The `--since` is the
  `refs/harness/last-learned` watermark (how far memory has already been digested);
  `--sha` is current `origin/main`. Also runnable by a human with `--rebuild`
  (regenerate memory from main) or `--dry-run` (print the candidate set plus
  justifications; open no PR; useful for evaluation runs).
- **Writes:** under `.claude/skills/expert/` (prefix-named reference files plus
  the `SKILL.md` index), `scripts/lints/*` + `scripts/local-checks.sh` wiring,
  and `AGENTS.md` files across the repo. **No `changelog.md`** — the git history
  of `learn/<sha>` PRs is the changelog.
- **Completion signal — two valid outcomes:**
  - **PR opened.** The pushed `learn/<sha>` branch + open PR. Idempotent via
    `git ls-remote origin learn/<sha>`. After the PR opens, the memory loop
    advances `refs/harness/last-learned` to `<sha>` (atomic CAS) and pauses new
    runs until you merge or close the PR.
  - **Nothing to learn.** Stdout `learn: nothing to learn from <sha>, skipping
    PR`; exit 0; no branch pushed. The memory loop advances the watermark
    regardless, so the next merge is picked up cleanly.
- **Session trail:** when a PR opens, the memory loop (`signal_learn_review`)
  attaches this run's headless `claude -p` session as a PR comment, so the human
  evaluating the memory changes can open the trace and troubleshoot *why* `/learn`
  routed a fact as it did. No action needed in this skill — the loop posts it.

## Hard nevers
- **Never invent facts beyond the merged diff** (P1) — and **never delete or
  "correct" developer-written direction just because the code doesn't show it
  yet**; reconcile it against the merge instead.
- **Never auto-merge.** Open the PR; the human steers (P8).
- **Never let AGENTS.md become an encyclopedia** — pointers into the Expert, under
  the caps (P4).
- **Never include a candidate lint you haven't run against current main.** A lint
  that reddens the merge it was born from is wrong.
- **Never frame an invariant as taste.** If it needs judgment, it's a `pattern-*`
  file (Expert), not an `invariant-*` file (lint/hard rule).
- **Never second-guess a memory edit that's already in the merged diff** (P7) —
  the human resolved a STUCK or made a deliberate correction; your job is to
  *extend* it, not vote on it.
- **Never accumulate without reconciling** (P9). A concept deleted from code is a
  reference file deleted in this PR. Inbound wikilinks get rewritten in the same
  commit.
- **Never write a wikilink that does not resolve** to a file in
  `expert/references/`. `check-expert-links.sh` will fail the PR.
- **Never open a PR for nothing-to-learn** (P10). Print the stdout line, exit 0,
  push nothing.
