# Dispatcher clone guide

`assets/ns-dispatch.sh.template` is a near-verbatim clone of the build loop's
`poll-and-dispatch.sh`. The ONLY differences carry the namespace. This file documents
exactly what changed and how to edit the phase chain — so you can explain the generated
dispatcher line by line and tune it without breaking an invariant.

## The namespace edits (all derive from `NS="__NS__"`)
| Concern | build loop | namespace loop |
|---|---|---|
| watch pattern | `prd/${SLUG}/*` | `${NS}/${SLUG}/*` |
| worktree base | `../<repo>-harness` | `../<repo>-harness-ns-${NS}` |
| ownership filter | `origin/feature/${1}:prds/${1}/prd.md` | `origin/feature/${NS}/${1}:prds/${1}/prd.md` |
| in-flight iter | `refs/.../feature/` lstrip=4 | `refs/.../feature/${NS}/` **lstrip=5** |
| cleanup iter | `refs/.../feature/` lstrip=4 | `refs/.../feature/${NS}/` **lstrip=5** |
| claim target | `feature/${feature}` | `feature/${NS}/${feature}` |
| active branch | `feature/${feature}` | `feature/${NS}/${feature}` |
| PR lookups | `gh pr view "feature/${feature}"` | `gh pr view "feature/${NS}/${feature}"` |

The `lstrip` bump (+1) is load-bearing: `refs/remotes/origin/feature/<ns>/<f>` has one more
path component than `refs/remotes/origin/feature/<f>`, so stripping `feature/<ns>` to recover
the bare `<f>` needs lstrip=5, not 4. Get this wrong and `feature` becomes `<ns>/<f>` and
every downstream path breaks.

**Unchanged on purpose:** sentinel paths (`specs/<f>/.planning-done`, `.validated`,
`.prd-passed`), the runner path (`prds/<f>/run-prd-test.sh`), all caps, the wipe, the HEAD
guard, the STUCK/convergence helpers' logic. The minter writes the same `prds/<feature>/`
layout, so the reused pipeline skills need no namespace awareness.

## The phase chain — where you add/remove a step
Step 3's `if/elif` block is the pipeline. Default proven chain (in the template):
1. `.planning-done` absent → `/spec-planning` (PLANNING_CAP)
2. `.validated` absent → `/spec-validate` (VALIDATE_CAP)
3. `.prd-passed` absent → run the oracle; bounded `/implement-mainspec` retry (IMPLEMENT_CAP)
4. `local-checks.sh` fails → auto-fix → `/fix-local-checks` (LOCAL_CHECKS_CAP)
5. no PR → open it
6. reviewer converged → HUMAN_REVIEW
7. reviewer has findings → `/address-feedback` (FEEDBACK_CAP)

**To add a phase** (e.g. `/security-review` between validate and implement): insert one
`elif` with its own sentinel check, its own `<STEP>_CAP` (declared in the config block and
env-overridable), and a `run_claude` / `signal_stuck` pair shaped exactly like the others.
Keep it BEFORE the oracle gate if it must hold before "done" can be evaluated.

**To remove a phase:** delete its `elif`. The next tick simply skips to the following
condition. Never delete the oracle gate or the wipe/HEAD guard.

## What NOT to let the user do
- Add `&` to any `claude -p` call (breaks synchronous one-step discipline, Inv 5).
- Add an LLM call to the decision logic (breaks Inv 5; makes it non-reproducible).
- Remove the wipe or HEAD guard (breaks crash recovery + Inv 6).
- Replace the atomic-rename claim with a marker file (breaks Inv 2/7).
- Point `/loop` at the dispatcher directly, bypassing `<ns>-tick.sh` (loop-infra updates on
  main would never reach the running loop).
- Make the dispatcher sync its own checkout (it would overwrite its own running file; the
  sync belongs in the tick wrapper, before `exec`).
- Run the loop from the build host worktree (it would race the build loop's host sync — use
  the dedicated `-ns-` infra worktree).
