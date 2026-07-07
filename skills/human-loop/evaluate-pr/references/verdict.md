# Verdict mechanics: checkout, run, approve, request changes

The plumbing behind Step 3 and Step 7. The skill only ever touches the PR (through `gh`)
and the human's own checkout. It never writes `.harness` and never pushes code — the
dispatcher owns sentinel lifecycle and the responder owns code changes.

## Detached checkout (Step 3)

The harness's per-feature worktree still holds `feature/<f>` during review, and git
refuses the same branch in two worktrees. So check out the PR head **detached**:

```bash
git fetch origin
git checkout --detach origin/feature/<f>
```

Then make it runnable. Prefer the project's own bootstrap so gitignored files
(node_modules, .env, generated code) exist:

```bash
[ -x scripts/bootstrap-worktree.sh ] && ./scripts/bootstrap-worktree.sh . || <project install>
```

Watch for port collisions with the human's own dev server (read ports from env if the
project supports it). Tear down any server you started before Step 8.

## Running the system (Step 4)

You know how to run this project from the Expert and the project conventions — this is
native; do not delegate to another skill. Drive the PRD's definition-of-done scenarios
first (they're the checks in `prds/<f>/run-prd-test.sh`), then push into edge cases:

- **Web/UI:** start the dev server, open the route, walk the happy path and the empty/
  error states with the human watching. Name UX feel explicitly.
- **API:** fire the representative `curl`s — happy path, missing/!malformed input, auth
  boundary — and read the responses together.
- **CLI/lib:** run the commands / exercise the API with real and degenerate inputs.

You can also just run `./prds/<f>/run-prd-test.sh` to see the definition of done pass —
but that proves *done*, not *understood*. The point of running live is the human seeing
behavior, so favor the hands-on walk over the green checkmark.

## Step 7 — The verdict (exactly one)

You are the last mile: there is no "send it back to the harness." Pick one.

### Merge
On the human's explicit go-ahead:

```bash
gh pr merge <pr> --merge   # or the project's policy (squash/rebase)
```

The merge triggers the dispatcher's cleanup (tears down the per-feature worktree and the
`human-review-<f>` sentinels) and the post-merge `/learn` pass (which reconciles memory from the merged diff).
This is where insights from your evaluation get recorded — whether they landed as **code**,
or as **memory edits the human wrote during the walk** (Expert / AGENTS.md, committed on the
branch). `/learn`'s P7 treats those human-authored edits as authoritative — to *extend*, not
second-guess — so a pattern the human seeded here survives the post-merge pass intact.

### Fix, then merge
If the walk surfaced something to change, make the edit **here, with the human**, in the
detached checkout, and push it to the PR branch. From a detached HEAD you push the commit
to the branch ref explicitly:

```bash
# ... make the scoped code edit (NOT prds/<f>/prd.md) ...
git add -A
git commit -m "fix(evaluate): <what changed and why>"
git push origin HEAD:feature/<f>      # detached HEAD → push to the branch ref
```

The reviewer re-runs on the push. When it posts `HARNESS_REVIEW_CLEAN` again the harness
re-hands the PR to you (a fresh "Ready for your review"); confirm and merge. Keep edits
scoped to what the human asked.

### Close
If the change is wrong or unwanted, on the human's explicit go-ahead:

```bash
gh pr close <pr> --comment "Closing after evaluation: <one-line reason>."
```

The cleanup pass tears down the worktree + sentinels. Closing is terminal; nothing is
handed back. If the right move is a different approach, that's a fresh `/intent`, not a
change request here.

## Step 8 — Always return

```bash
git checkout main
```

Leave the user where they started. Never leave them on a detached HEAD or a feature
branch.

## Hackable seams

- **Gate softness.** Step 6's "do you understand?" is soft by default (small changes can
  opt out). A team that wants firmer review can require the walk-through before any
  approval — edit the gate language in `SKILL.md`.
- **Merge policy.** Squash vs. merge vs. rebase, and whether the skill merges at all or
  only approves and lets the human click merge — adjust the `gh pr merge` line above.
