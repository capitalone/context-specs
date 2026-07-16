#!/usr/bin/env bash
# plan-in-isolation.sh — re-run this project's spec-planning for a feature, at HEAD,
# with the env's CURRENT context, and capture the plan WITHOUT touching any real branch.
# The shared engine behind every evals/spec-planning/ case (Tier 2, integration).
#
#   Usage: plan-in-isolation.sh <feature> <out-dir> [--without <relpath>] [--env-root <dir>]
#
#   <feature>          feature slug, e.g. pattern-to-pip. Its prds/<feature>/prd.md is the
#                      planning input; it may be a merged OR an in-progress feature.
#   <out-dir>          where to drop the captured plan (created; caller keeps it gitignored)
#   --without <relpath> OPTIONAL. A context path under the worktree to REMOVE before planning
#                      — the without-shard arm. Typically a shard, e.g.
#                      `.claude/skills/expert/invariant-timezone-safe-dates.md`. Omit for the
#                      full-context arm. (Line-level AGENTS.md removal: pass a pre-edited
#                      AGENTS.md as an overlay via the caller; this flag removes whole files.)
#   --env-root <dir>   the environment repo (default: git toplevel of CWD). Its CURRENT
#                      working-tree Expert (.claude/skills/expert) is the thing under test.
#
#   On success prints:  <out-dir>/plan   (a dir holding mainspec.md + slices/)
#   Exit 0 = a plan was produced; non-zero = it wasn't (message on stderr).
#
# WHY THIS EXISTS — the two facts that make hand-rolling this wrong:
#   1. The harness's tier-1 skills (incl. spec-planning) reach an environment as
#      GITIGNORED SYMLINKS in .claude/skills/. A plain `git worktree add` does NOT carry
#      them, so `claude -p "/spec-planning …"` answers "Unknown command". You MUST re-link
#      them into the fresh checkout first.
#   2. The correct `claude -p` permission posture is the HARNESS's, not a guess. It defaults
#      to `--permission-mode auto` and is overridable per-environment in .harness/env. We
#      read the effective value the same way the dispatcher does — never hardcode
#      --dangerously-skip-permissions / bypassPermissions.
# This script INSPECTS the harness instead of assuming it, so it stays correct as the
# harness evolves. If you are adapting it, keep that principle.
#
# We plan at HEAD: the two eval arms differ only by --without, so the delta between them is
# attributable to that context alone. The planning commit lands only in a throwaway worktree
# that is deleted here — no real branch is touched.
#
# RUN IT FROM A HUMAN SHELL. It launches an autonomous, file-writing `claude -p`; an agent
# in auto mode is blocked from spawning that.
set -uo pipefail

feature=""; out_dir=""; without=""; env_root=""
while (( $# )); do
  case "$1" in
    --without)   without="${2:?--without needs a relpath}"; shift 2 ;;
    --env-root) env_root="${2:?--env-root needs a dir}"; shift 2 ;;
    -*)         echo "plan-in-isolation: unknown flag $1" >&2; exit 64 ;;
    *)          if [[ -z "$feature" ]]; then feature="$1"; elif [[ -z "$out_dir" ]]; then out_dir="$1";
                else echo "plan-in-isolation: unexpected arg $1" >&2; exit 64; fi; shift ;;
  esac
done
[[ -n "$feature" && -n "$out_dir" ]] \
  || { echo "usage: plan-in-isolation.sh <feature> <out-dir> [--without <relpath>] [--env-root <dir>]" >&2; exit 64; }
env_root="${env_root:-$(git rev-parse --show-toplevel)}"
env_root="$(cd "$env_root" && pwd)"

die() { echo "plan-in-isolation: $*" >&2; exit 1; }
command -v claude >/dev/null 2>&1 || die "claude CLI not found."
[[ -d "$env_root/.claude/skills/expert" ]] || die "no Expert at $env_root/.claude/skills/expert."
[[ -f "$env_root/prds/$feature/prd.md" ]] || die "no PRD at $env_root/prds/$feature/prd.md."

# --- effective headless permission posture: the dispatcher's default, then the
#     environment's committed override (exactly how poll-and-dispatch.sh does it). ---
CLAUDE_PERM_ARGS=( --permission-mode auto )       # harness default
# shellcheck disable=SC1091
[[ -f "$env_root/.harness/env" ]] && source "$env_root/.harness/env"

# --- disposable worktree at HEAD (NOT a harness-managed worktree) ------------------
wt="$(mktemp -d "${TMPDIR:-/tmp}/specplan-eval-${feature}.XXXXXX")"
sid="$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "noid-$$-$RANDOM")"
cleanup() { git -C "$env_root" worktree remove --force "$wt" >/dev/null 2>&1 || rm -rf "$wt"; }
trap cleanup EXIT

echo "plan-in-isolation: worktree @ HEAD  (feature=$feature, without=${without:-none}, session=$sid)" >&2
git -C "$env_root" worktree add --detach "$wt" HEAD >/dev/null 2>&1 \
  || die "git worktree add failed at HEAD."

# The thing under test: overlay the env's CURRENT working-tree Expert onto the checkout, so
# uncommitted shard edits (the reason you're running this) are what plans.
rm -rf "$wt/.claude/skills/expert"
mkdir -p "$wt/.claude/skills"
cp -R "$env_root/.claude/skills/expert" "$wt/.claude/skills/expert"

# Without-shard arm: remove the context path under test before planning.
if [[ -n "$without" ]]; then
  [[ -e "$wt/$without" ]] || die "--without target not found in worktree: $without"
  rm -rf "${wt:?}/$without"
  echo "plan-in-isolation: removed $without" >&2
fi

# Re-link the tier-1 skill symlinks so /spec-planning resolves.
if command -v context-specs >/dev/null 2>&1; then
  context-specs link "$wt" >/dev/null 2>&1 || die "context-specs link failed."
elif [[ -n "${CONTEXT_SPECS_HOME:-}" && -x "$CONTEXT_SPECS_HOME/bin/context-specs" ]]; then
  "$CONTEXT_SPECS_HOME/bin/context-specs" link "$wt" >/dev/null 2>&1 || die "context-specs link failed."
else
  die "can't re-link skills: 'context-specs' not on PATH and CONTEXT_SPECS_HOME unset.
   Export CONTEXT_SPECS_HOME=<harness repo> or put context-specs on PATH."
fi
[[ -e "$wt/.claude/skills/spec-planning/SKILL.md" ]] \
  || die "spec-planning skill not linked into the worktree — /spec-planning would 404."

# --- invoke spec-planning the harness's way: cd into the worktree, slash form, the
#     effective posture, a discoverable session id. Output-only: whatever it commits dies
#     with the worktree. ---
echo "plan-in-isolation: running /spec-planning $feature …" >&2
( cd "$wt" && claude -p --session-id "$sid" "${CLAUDE_PERM_ARGS[@]}" "/spec-planning ${feature}" ) \
  >"$out_dir.claude.stdout" 2>"$out_dir.claude.stderr" || true

mainspec="$wt/specs/$feature/mainspec.md"
[[ -f "$mainspec" ]] || die "no mainspec produced (see ${out_dir}.claude.stdout / .stderr).
   Common cause: the skill 404'd or asked a question. This is the run to debug the
   invocation against — the setup above is verified, the prompt/skill contract is not."

# --- capture the plan off disk, then let the trap delete the worktree ---
mkdir -p "$out_dir/plan"
cp "$mainspec" "$out_dir/plan/mainspec.md"
if [[ -d "$wt/specs/$feature/slices" ]]; then
  cp -R "$wt/specs/$feature/slices" "$out_dir/plan/slices"
fi
echo "$out_dir/plan"
