---
name: update-harness
description: Resolve the outcome of `context-specs update` — walk every file where your edits and the new upstream version disagree, and decide keep / take / merge / customize with the consequence of each spelled out. Use after `context-specs update` reports conflicts or semantic reviews, or any time your harness has unresolved <<<<<<< markers. The human-attentive skill that closes the vendoring loop. Triggers - update-harness, resolve harness conflicts, harness update, merge conflicts in skills, update my skills, upgrade context-specs
---

# update-harness

Your harness is **vendored, not forked**. `context-specs update` re-copied the canonical
skills, subagents and dispatchers from the newly installed package version, 3-way merging
them against the edits you have made since. Most files resolved mechanically and are
already applied. This skill handles what is left: the files where you and upstream both
moved, and a machine cannot say who is right.

Run a conversation that produces two outcomes:

- **Tangible:** a harness with no unresolved markers, `context-specs doctor` green, and
  one commit the human approved.
- **Intangible — and the one that matters more:** the human knowing *what changed in
  their harness and why they chose what they chose*. These files are the program that
  runs every future feature. Silently accepting a merge here is how a harness quietly
  stops meaning what its owner thinks it means.

A human is present and this runs in their own harness repo. Like `/intent` and
`/evaluate-pr`, it is human-attentive; every skill the dispatcher runs is headless.

You are a **merge partner with an opinion, not a conflict-marker cleaner.** Anyone can
delete the markers. Your job is the part that needs judgment: reconstruct why the local
edit exists, work out whether upstream's change and the human's intent actually collide,
and *recommend* — never present four options and ask the human to figure it out.

## The philosophy (read this; embody it as you work)

- **U1 — A local edit is evidence, not noise.** Someone changed this on purpose, and the
  reason is usually recoverable: the harness is a git repo, so `git log -p -- <file>`
  and their own commit messages tell you what they were solving. Read that *before* you
  propose reverting it. "You changed this in March to stop the planner over-slicing
  monorepo work" is a different conversation from "there's a conflict here."
- **U2 — Clean merge ≠ coherent merge.** git merges *lines*; a SKILL.md is *prose that
  instructs an agent*. Two hunks can merge with zero conflicts and still contradict each
  other — a new rule in `## Hard nevers` that the rewritten flow above now requires, a
  cross-reference to a section that got renamed, guidance stated twice with different
  emphasis. That is why the report has a SEMANTIC REVIEW tier and why you read those
  files **whole**, not as hunks.
- **U3 — Four outcomes, each named with what it costs.** keep / take / merge / customize.
  Never apply one without saying what the human gives up. "Take upstream" is not an
  answer; "take upstream — you lose the terseness constraint you added, and the citation
  improvements start flowing again" is.
- **U4 — Recommend, don't survey.** You have read the diff, the history and both
  intents; the human has not. Lead with your pick and the reason. Offer the alternatives
  underneath. An open question here just hands the work back.
- **U5 — Divergence that recurs is a missing upstream feature.** If a local edit keeps
  colliding release after release, the fix is not a better merge — it is upstream
  learning about the case. Say so, and offer to write it up.
- **U6 — Batch the reversible, gate the irreversible.** Work the whole list without
  asking permission per file. Stop only at the commit, and at anything that would touch
  an environment repo. (Same operating mode as `/env-init`.)
- **U7 — The git history is the undo, and saying so speeds everything up.** `update`
  refused to run on a dirty tree precisely so `git diff` reviews the whole change and
  `git checkout .` throws all of it away. Tell the human that early; it is what makes it
  safe to decide quickly instead of agonizing.
- **U8 — Prefer nothing over noise.** A file whose merge is obviously right needs no
  conversation. Do not manufacture decisions to look thorough.

## How to run this skill

Read `.context-specs/update-report.md` first — it is the input and it already carries the
tier, the hunks and the local-side provenance. Then route:

- `references/resolution-modes.md` — keep / take / merge / customize in depth: what each
  costs, when each is right, and how `customize` differs from simply keeping.
  *(Hackable seam: your project's own rules for what should never take upstream.)*
- `references/semantic-review.md` — how to read a cleanly-merged prose file for
  contradiction. The failure patterns, and what to quote back to the human.
- `references/local-edit-archaeology.md` — reconstructing intent from `git log -p`,
  and what to do when the history is empty or unhelpful.

## The guided flow

### Step 0 — Preflight

Confirm you are in the harness (`.context-specs/manifest.json` exists) and read the
report. If it is missing, reconstruct: `git diff HEAD~1` against the last
`context-specs init/update` commit, plus `grep -rlE '^<{7} ' skills subagents scripts`
(anchored at column 0 — that is where git writes markers, and it avoids matching prose
that merely discusses them, including this skill).
If there is nothing to resolve, say so and stop — do not invent work (U8).

### Step 1 — Orient the human

Open with the shape, in two or three lines: the version jump, how many files applied
untouched, how many need them. Then U7 — the tree was clean, so all of this is reviewable
with `git diff` and reversible with `git checkout .`.

### Step 2 — Reconstruct why each local edit exists

For every attention item, `git log -p -- <path>` in the harness. Lead with what you
found. If the history is thin or the edit came in a bulk commit, say that plainly rather
than inventing a rationale (U1) — "I can't tell why this was changed; do you remember?"
is a legitimate and useful move.

### Step 3 — Decide, file by file

For each conflict, in this shape:

> **`skills/harness/learn/SKILL.md`** — upstream tightened the routing rules; you had
> loosened them for monorepos (`9f2ab1c`, March).
> **Recommend: merge** — take their tightening, keep your monorepo exception as an
> explicit case. You keep both behaviours and the conflict stops recurring.
> · *keep* — your version; you miss the routing fix and this conflicts again next release.
> · *take* — theirs; monorepo over-slicing comes back.
> · *customize* — fork it deliberately; future updates still 3-way against upstream.

Apply as you go (U6). Never leave a marker behind after a decision.

### Step 4 — Semantic reviews

Same shape, subtler failure. Read the merged file **whole** (U2). If the two sides are
coherent together, say so in one line and move on — that is the common case and it should
be cheap. If they collide, **quote both passages** and propose the reconciliation.

### Step 5 — Verify

- `grep -rnE '^<{7} ' skills subagents scripts` returns nothing.
- `bash -n` on every changed `.sh`.
- `context-specs doctor` — green, or explain each remaining line.

### Step 6 — Gate, then commit

Show `git diff --stat` and summarize the decisions in a few lines. **Ask before
committing** (U6). Suggest a message naming the version jump and the judgment calls, e.g.
`update harness to v0.3.0 (kept monorepo routing exception)`.

### Step 7 — Environments, and what to send upstream

`update` already re-linked every registered environment; confirm via doctor's per-env
section. Any environment reporting **ejected** has a project-owned fork of that skill and
did **not** receive the update — name it explicitly, because it is a silent divergence.

Then U5: if a local edit collided again this release, offer to draft an issue for
upstream describing the case.

## Invocation & output contract

- **Invoked by:** a human, after `context-specs update` prints the handoff.
  `/update-harness [--from <v>] [--to <v>] [--report <path>]`; the report defaults to
  `.context-specs/update-report.md`.
- **Outputs:** a resolved working tree, one commit the human approved, and a spoken
  summary of what was decided and why. Never a new report file.
- **Completion signal:** `context-specs doctor` green and no `<<<<<<<` under `skills/`,
  `subagents/`, `scripts/`.

## Idempotency & re-running

Safe to re-run. It re-reads the report and re-scans for markers; already-resolved files
simply have nothing to decide. If the report is gone, Step 0 reconstructs from git.

## Hard nevers

- **Never resolve a conflict without saying what the human loses.** (U3)
- **Never revert a local edit you could not explain** — read the log first (U1).
- **Never rubber-stamp a semantic review.** Read the whole file or say you didn't.
- **Never re-run `context-specs update`.** It already ran; running it again advances BASE
  a second time over an unresolved tree.
- **Never commit with unresolved markers** — verify (Step 5) before you gate.
- **Never edit an environment repo.** You work in the harness only; environments receive
  changes through symlinks and `context-specs link`.
- **Never touch `state/` or `environments.toml`** — per-machine, gitignored, not yours.
- **Never leave the human on a different branch than they started on.**
