#!/usr/bin/env bash
# plan-in-isolation.sh — re-run this project's spec-planning for a feature, at a
# historical checkout, with TODAY'S Expert, and capture the plan WITHOUT touching
# any real branch. The shared engine behind every evals/long-term-memory/ case.
#
#   Usage: plan-in-isolation.sh <feature> <pre-plan-sha> <out-dir> [env-root]
#
#   <feature>       feature slug, e.g. pattern-to-pip
#   <pre-plan-sha>  the (A) commit: prd.md + run-prd-test.sh present, specs/<f>/ ABSENT
#                   (harvest-eval-inputs.sh prints it). We plan against this code.
#   <out-dir>       where to drop the captured plan (created; caller keeps it gitignored)
#   [env-root]      the environment repo (default: git toplevel of CWD). Its CURRENT
#                   working-tree Expert (.claude/skills/expert) is the thing under test.
#
#   On success prints:  <out-dir>/plan   (a dir holding mainspec.md + slices/)
#   Exit 0 = a plan was produced; non-zero = it wasn't (message on stderr).
#
# WHY THIS EXISTS — the two facts that make hand-rolling this wrong:
#   1. The harness's tier-1 skills (incl. spec-planning) reach an environment as
#      GITIGNORED SYMLINKS in .claude/skills/. A plain `git clone`/`git worktree
#      add` does NOT carry them, so `claude -p "/spec-planning …"` answers
#      "Unknown command". You MUST re-link them into the fresh checkout first.
#   2. The correct `claude -p` permission posture is the HARNESS's, not a guess.
#      It defaults to `--permission-mode auto` and is overridable per-environment
#      in .harness/env. We read the effective value the same way the dispatcher
#      does — never hardcode --dangerously-skip-permissions / bypassPermissions.
# This script INSPECTS the harness instead of assuming it, so it stays correct as
# the harness evolves. If you are adapting it, keep that principle.
#
# RUN IT FROM A HUMAN SHELL. It launches an autonomous, file-writing `claude -p`;
# an agent in auto mode is blocked from spawning that. The planning commit lands
# only in a throwaway worktree that is deleted here, so no real branch is touched.
set -uo pipefail

feature="${1:?usage: plan-in-isolation.sh <feature> <pre-plan-sha> <out-dir> [env-root]}"
sha="${2:?missing <pre-plan-sha> (the (A) commit — see harvest-eval-inputs.sh)}"
out_dir="${3:?missing <out-dir>}"
env_root="${4:-$(git rev-parse --show-toplevel)}"
env_root="$(cd "$env_root" && pwd)"

die() { echo "plan-in-isolation: $*" >&2; exit 1; }
command -v claude >/dev/null 2>&1 || die "claude CLI not found."
[[ -d "$env_root/.claude/skills/expert" ]] || die "no Expert at $env_root/.claude/skills/expert."
git -C "$env_root" cat-file -e "${sha}^{commit}" 2>/dev/null || die "sha $sha not found in $env_root."

# --- effective headless permission posture: the dispatcher's default, then the
#     environment's committed override (exactly how poll-and-dispatch.sh does it). ---
CLAUDE_PERM_ARGS=( --permission-mode auto )       # harness default
# shellcheck disable=SC1091
[[ -f "$env_root/.harness/env" ]] && source "$env_root/.harness/env"

# --- disposable worktree at the (A) checkout (NOT a harness-managed worktree) ------
wt="$(mktemp -d "${TMPDIR:-/tmp}/ltm-eval-${feature}.XXXXXX")"
sid="$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "noid-$$-$RANDOM")"
cleanup() { git -C "$env_root" worktree remove --force "$wt" >/dev/null 2>&1 || rm -rf "$wt"; }
trap cleanup EXIT

echo "plan-in-isolation: worktree @ $sha  (feature=$feature, session=$sid)" >&2
git -C "$env_root" worktree add --detach "$wt" "$sha" >/dev/null 2>&1 \
  || die "git worktree add failed at $sha."

# The thing under test: overlay the env's CURRENT Expert onto the historical tree.
rm -rf "$wt/.claude/skills/expert"
mkdir -p "$wt/.claude/skills"
cp -R "$env_root/.claude/skills/expert" "$wt/.claude/skills/expert"

# Re-link the tier-1 skill symlinks so /spec-planning resolves. Prefer the project's
# own bootstrap (its deterministic header links skills); fall back to `context-specs
# link`. We only need the symlinks, not deps — but the project bootstrap is the
# faithful path if it's cheap. Try the direct link first (fast, sufficient).
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

# --- invoke spec-planning the harness's way: cd into the worktree, slash form,
#     the effective posture, a discoverable session id. Output-only: whatever it
#     commits dies with the worktree. ---
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
