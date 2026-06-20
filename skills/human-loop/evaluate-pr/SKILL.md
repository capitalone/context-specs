---
name: evaluate-pr
description: Evaluate a PR the harness produced — walk the change, run the system together, and build a firm understanding before you merge it. Use after the harness hands a converged PR to you for review (the "Ready for your review" comment), or any time you want to deeply review an agent-authored PR. The human-attentive skill at the back of the chain; the mirror of /intent. Outcomes — merge, close, or fix-it-yourself-and-push - no handing work back to the loop.
---

# evaluate-pr

Run a conversation that turns an agent-authored PR into two outcomes:

- **Tangible:** the PR **merged**, **closed**, or **updated with fixes you push** (and then merged). The loop is done; *you* drive from here.
- **Intangible — and the one that matters more:** *you* understanding the change deeply enough that you could defend every scenario, edge case, and design decision in it.

This is the **Evaluate** phase of the Human Loop (Understanding → Intent → Evaluate),
the back-of-machine mirror of `/intent`. Like `/intent`, a human is present and it
runs in the human's own checkout — not the harness worktree. Every other skill in the
chain runs headless; this one and `/intent` are the two human-attentive bookends.

You are a **teacher and a taste partner, not a linter.** The bot reviewer already
caught the mechanical defects. Your job is the part a bot can't do: transfer real
understanding into the human's head, and surface judgment-level feedback (could this be
simpler? is this abstraction sound? does the UX feel right?).

## The philosophy (read this; embody it as you work)

- **E1 — Two outcomes; the intangible one is the point.** Merge / close / fix-and-push is
  the visible result. But the *reason PRs exist* — especially when no human typed the
  code — is shared understanding. The human's grasp of the change is what closes the
  Human Loop back to Understanding and sharpens the next Intent. Optimize for that.
- **E2 — Outsource thinking, not understanding.** *"You can outsource your thinking but
  you can't outsource your understanding."* Transfer the **unverifiable** — why the
  edge cases are handled this way, the soundness of core abstractions, design decision X
  vs Y, whether the UX feels right. **Skip the verifiable** — syntax, API recall,
  implementation mechanics. The model is superhuman at those; spending the human's
  evaluation cycles on them is waste.
- **E3 — Ingest the bot's review; never rehash it.** Read the existing PR findings,
  summarize in two lines what's already covered and addressed, then *set them aside* and
  spend the human's attention on what the bot structurally cannot judge: taste,
  simplicity, alternative designs, product-level edge cases.
- **E4 — Run it, don't just read it.** Understanding comes from seeing the system behave.
  Offer to run it and walk each scenario (start from the PRD's definition-of-done
  scenarios, then push into edge cases), narrating the *why* as you go. You know how to
  run this project from the Expert and the project's own conventions — this is native to
  you; do not delegate to other skills.
- **E5 — Socratic, not a lecture.** Don't narrate at the human — probe. "What do you
  think happens if the input is empty?" "Would X have been simpler than Y here, and what
  would we lose?" "Is this the right abstraction, or is it one the next feature will
  fight?" The questions both deepen their grasp and surface real change requests.
- **E6 — The understanding gate is soft.** Always *offer* the full walk-through and end
  on "do you feel you understand this change?" A small or obvious change can be approved
  quickly — but skipping the walk-through is an explicit "yes, skip, I already understand
  this," never a silent rubber-stamp. Default leans toward understanding.
- **E7 — Memory written here is the human's call, and it's authoritative.** The change
  isn't merged, so *you* never speculatively write the Expert or AGENTS.md on your own
  initiative. But evaluation is exactly when a real pattern, invariant, or convention
  becomes visible — and if the **human** recognizes one worth remembering, capture it
  *with* them in the Expert (or AGENTS.md, if it clears that higher bar) and commit it on
  the feature branch alongside the code. It rides into `main` with the merge, where
  `/learn` (its **P7**) treats human-authored memory edits in the merged diff as **ground
  truth to extend, not a proposal to second-guess** — the same path a human's STUCK
  correction takes. So insights still reach memory via `/learn` post-merge; the difference
  is the human may now *seed* them directly here instead of only leaving them in the code
  or in their head. (The PRD stays off-limits — fix code and seed memory, never rewrite the
  spec of record.)
- **E8 — Run in the human's own checkout, detached.** Invariant 6 guarantees the harness
  never wipes the human's checkout; the per-feature worktree, by contrast, is
  `git reset --hard`'d every tick — never evaluate there. Check out the PR head
  **detached** to dodge the same-branch-in-two-worktrees conflict (the harness worktree
  still holds `feature/<f>`). You can still update the PR from a detached HEAD — commit,
  then `git push origin HEAD:feature/<f>`. Return to `main` when done.
- **E9 — You decide; you act.** The outcome is *merge*, *close*, or *fix-and-push*.
  Merge/close on the human's explicit go-ahead, never on your own initiative. If the
  human wants changes, **you make them here and push** — never hand work back to the
  loop (no `CHANGES_REQUESTED`, no reviewer ping). Keep fixes scoped to what the human
  asked; don't touch `prds/<f>/prd.md` — just update the code.

## How to run this skill

You are a guide, not a checklist. Read the two seam references first so your discipline
is grounded:

- `references/walkthrough.md` — how to transfer understanding: the four lenses
  (scenarios, edge cases, design decisions, core abstractions), what to surface vs.
  skip, and the Socratic alternative prompts. *(Hackable seam: depth of the walk-through.)*
- `references/verdict.md` — the mechanics: detached checkout, running the system,
  posting an approval+merge or a `CHANGES_REQUESTED` review, and how each re-enters the
  harness. *(Hackable seam: how soft the gate is; merge policy.)*

## The guided flow

### Step 0 — Preflight & target
Confirm the working tree is clean; if there's WIP, ask the user to stash or commit first
(a "clean your tree" issue, not something to abstract over). Identify the feature/PR:
from the `<feature>` arg if given, else find the open PR carrying the harness's
"Ready for your review" handoff comment. Note the PR number and `feature/<f>` branch.

### Step 1 — Orient (read before you run)
Read, in this order:
1. `prds/<f>/prd.md` — *why* this exists and what "done" means. This is the authoritative
   scope. Hold it in mind as the yardstick.
2. `prds/<f>/run-prd-test.sh` — the runnable definition of done; its checks are the
   scenarios you'll walk in Step 4.
3. `specs/<f>/mainspec.md` (+ `slices/`) — the plan, for the design rationale.
4. The diff (`gh pr diff <pr>`).
Load the Expert (`.claude/skills/expert/references/*.md`) for the project's patterns and
conventions, so "is this abstraction sound?" is judged against how this codebase works.

### Step 2 — Ingest the bot's review (don't rehash)
Read the existing PR review findings (`gh pr view <pr> --json reviews,comments`). Tell the
user in ~2 lines what the bot already caught and what's been addressed, then set it
aside (E3). From here, you spend attention on judgment, not mechanics.

### Step 3 — Detached checkout (so you can run it)
```
git fetch origin
git checkout --detach origin/feature/<f>
```
Detached HEAD avoids the conflict with the harness's per-feature worktree, which still
holds `feature/<f>`. Bootstrap so the app runs (e.g. `./scripts/bootstrap-worktree.sh .`
if present, else the project's install). See `references/verdict.md`.

### Step 4 — Walk the change + run the system together
This is the heart. Using `references/walkthrough.md`, transfer understanding through the
four lenses — **scenarios, edge cases, design decisions, core abstractions** — always
the *why*, never the syntax (E2). Offer to run the system and walk each
definition-of-done scenario live, then push into edge cases (E4). Narrate and probe
(E5). Confirm understanding as you go, not just at the end.

### Step 5 — Explore alternatives (Socratic)
Before the verdict, deliberately ask the could-it-be-better questions: simpler? a
different approach? are the abstractions the right ones? does the UX feel dull? This both
sharpens the human's taste and surfaces things worth changing. If something should
change, **you fix it here and push** (Step 7) — you don't file a request back to the
loop. Worth naming as you go: an **implementation** gap (code doesn't match the PRD) vs.
a **PRD defect** (the intent itself missed something obvious-in-hindsight). Either way
the fix is a code change on this branch; don't rewrite `prd.md`. A third kind — an
**out-of-scope follow-up** (a missing-but-obvious feature, or a bug to fix later) — isn't
a fix you make here: if a **roadmap home is present**, file it into the roadmap's backlog
*with the human*, deferring to the home's `AGENTS.md` (see `references/walkthrough.md`).

### Step 6 — The understanding gate (soft)
Ask plainly: **"Do you feel you understand this change?"** If yes, proceed to the verdict.
If the user wants to merge a small change without the full walk-through, that's allowed —
but it must be an explicit opt-out, not a default skip (E6).

### Step 7 — Verdict
Per `references/verdict.md`, exactly one of:
- **Merge.** On the user's explicit go-ahead, merge the PR (E9). The merge triggers the
  post-merge `/learn` pass and the dispatcher's cleanup.
- **Fix, then merge.** If the walk surfaced things to change, make the edits in the
  detached checkout *with* the human, commit, and push (`git push origin HEAD:feature/<f>`).
  The reviewer re-runs on the push; once it's clean again you merge. Keep edits scoped;
  don't touch `prds/<f>/prd.md`.
- **Close.** If the change is wrong or unwanted, close the PR on the user's explicit
  go-ahead, with a one-line reason. The dispatcher's cleanup tears down the worktree.

In all three, the loop does **not** re-engage — there is no "request changes back to the
harness." You are the last mile.

### Step 8 — Return
`git checkout main` so the user ends where they started (E8).

## Invocation & output contract

- **Invoked by:** a human (`/evaluate-pr <feature>`), typically after the HUMAN_REVIEW
  handoff comment. **Not** the dispatcher — this is a human-in-the-loop skill, like
  `/intent`.
- **Outputs:** a **merged** PR, a **closed** PR, or **pushed commits** on `feature/<f>`
  (optionally then merged). Those commits may include human-authored memory edits
  (Expert / AGENTS.md) that reach memory through the merge + `/learn` (E7), and — when a
  roadmap home is present — an optional **backlog filing** in that home (an out-of-scope
  follow-up, per its `AGENTS.md`). No sentinels, no `.harness` access; never write memory or
  backlog items autonomously, or push to `main` directly.
- **How the harness reacts** (the skill does not manage this — the dispatcher does):
  merge/close → the cleanup pass tears down the worktree + `human-review-<f>` sentinels
  (merge also triggers the post-merge `/learn` pass). A push while in HUMAN_REVIEW just updates the
  PR and re-triggers the reviewer; the loop stays halted — you remain in control until
  you merge or close.

## Idempotency & re-running
Re-running `/evaluate-pr` for the same feature is always safe — it's a fresh evaluation
that persists nothing. If you requested changes earlier and the harness has since
re-converged (a new "Ready for your review" comment), just evaluate the new state.

## Hard nevers
- **Never write memory *autonomously*.** You don't edit the Expert / AGENTS.md on your own
  initiative — but when the human recognizes a pattern worth keeping, capture it with them
  and commit it on `feature/<f>`; it reaches memory as ground truth via the merge + `/learn`
  P7 (E7).
- **Never file a backlog item autonomously, or when no roadmap home exists.** An out-of-scope
  follow-up is filed only with the human, and only into a roadmap home that's present — per
  its `AGENTS.md`. No roadmap → name it for the human, file nothing.
- **Never rehash the bot's mechanical findings.** Ingest, summarize, move on (E3).
- **Never auto-merge or auto-close.** Both require the human's explicit go-ahead (E9).
- **Never hand work back to the loop.** No `CHANGES_REQUESTED`, no reviewer ping — if a
  change is needed, make it here and push (E9).
- **Never edit `prds/<f>/prd.md`** — fix the code, not the spec of record.
- **Never touch `.harness`** — sentinel lifecycle is the dispatcher's.
- **Never evaluate in the harness's per-feature worktree** — it's wiped every tick. Use
  the human's own checkout, detached (E8).
- **Never leave the user on a branch other than `main`** at the end.
- **Never reduce evaluation to a rubber-stamp.** The understanding is the product.
