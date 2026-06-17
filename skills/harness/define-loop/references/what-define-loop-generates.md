# What define-loop generates

The full inventory of artifacts for a namespace `<ns>`, what each is cloned from, and what's
reused untouched. Use this to set the user's expectations and to drive the re-run diff.

## Generated (new files only)
| Path | Cloned from | Kind |
|---|---|---|
| `scripts/<ns>-dispatch.sh` | `assets/ns-dispatch.sh.template` | canonical + phase edits |
| `scripts/<ns>-tick.sh` | `assets/ns-tick.sh.template` | canonical |
| `.claude/skills/<ns>-loop/SKILL.md` | `assets/ns-loop-SKILL.md.template` | canonical (the `/loop` shim) |
| `.claude/skills/intent-<ns>/SKILL.md` | `assets/intent-ns-SKILL.md.template` | canonical (the minter) |
| `.claude/skills/intent-<ns>/references/runner-recipes.md` | `/intent`'s copy | copied + branch examples adapted |
| `.claude/skills/intent-<ns>/references/right-reason.md` | `/intent`'s copy | copied + branch examples adapted |
| `loops/<ns>/prd-template.md` | `assets/prd-template.md.template` | filled-in (`## Loop conventions`) |
| `loops/<ns>/oracle.md` | `assets/oracle.md.template` | filled-in (judge rubric) |
| `loops/<ns>/learn-lens.md` | `assets/learn-lens.md.template` | passive, unused in v1 |
| `loops/<ns>/README.md` | `assets/loop-README.md.template` | filled-in (human-facing) |

Plus one runtime worktree provisioned (not committed): `../<repo>-harness-ns-<ns>/`.

## Reused UNCHANGED (never modified or regenerated)
- `scripts/poll-and-dispatch.sh`, `scripts/harness-tick.sh`, the `prd` build loop.
- `scripts/learn-tick.sh`, the `learn` memory loop.
- `scripts/harness-lib.sh` — the shared helpers (`run_claude`, `worktree_for`,
  `bootstrap_worktree`, `render_sessions_table`); the new dispatcher *sources* it.
- `scripts/local-checks.sh`, `scripts/bootstrap-worktree.sh` — the new loop reuses both.
- Every pipeline skill: `/spec-planning`, `/spec-validate`, `/implement-mainspec`,
  `/fix-local-checks`, `/address-feedback`. They're path-based, so a `feature/<ns>/<f>`
  worktree is just another worktree to them.

## Known v1 simplifications (deliberate; deferred)
- **Dispatcher-local helpers are duplicated.** `signal_stuck` / `signal_human_review` /
  `reviewer_converged` / `has_prd` live inside the generated dispatcher (they're
  dispatcher-local in `poll-and-dispatch.sh` today). Duplicating keeps the build loop
  untouched; a later DRY pass could promote them to `harness-lib.sh`.
- **`learn` is not namespace-aware.** `loops/<ns>/learn-lens.md` is generated but inert until
  a future version teaches `learn` to read it by branch prefix.
- **Event-sourced loops are out of scope.** This skill only mints from a human-authored
  work-item. A scanner/webhook-fed or merge-watermark loop is a future iteration.
