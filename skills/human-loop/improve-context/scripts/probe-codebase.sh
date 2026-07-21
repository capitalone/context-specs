#!/usr/bin/env bash
# probe-codebase.sh — ask one localization question against this project's CODEBASE ALONE,
# at a chosen git ref, and capture the answer + its (discoverable) session id. The Tier-1
# engine behind evals/codebase/ cases: "does the structure itself tell a fresh agent where a
# change belongs and what precedent to copy?"
#
# It builds a sandbox holding the codebase at <ref> with the PROSE LEVERS REMOVED — the
# Expert (`.claude/skills/expert`), every `AGENTS.md`, and every `CLAUDE.md` — then runs one
# bare `claude -p` (no slash command) that must answer from names, structure, and neighbors
# by search alone. It is the exact INVERSE of probe-expert.sh:
#
#     probe-expert.sh    sandbox = the Expert, NO codebase   → isolates prose
#     probe-codebase.sh  sandbox = the codebase, NO prose    → isolates structure
#
# Each isolates one lever by deleting the other. The strip is load-bearing: a shard that
# describes structure exists to COMPENSATE for structure (harnessability.md, H2), so leaving
# it in would let prose carry the answer the folder name should have carried — masking exactly
# the defect being measured.
#
# There is no "without the codebase", so a case's two arms are BEFORE vs. AFTER a refactor:
# arm A the working tree, arm B `--at <pre-refactor-ref>`. Same version-vs-version shape as
# probe-expert.sh's --prev/--prev-from.
#
#   Usage:
#     probe-codebase.sh <scenario-file> <out-dir> [--at <ref>] [--env-root <dir>]
#
#   <scenario-file>  a localization question (the eval fixture's scenario.md).
#   <out-dir>        created; receives answer.txt + session-id; printed on success.
#   --at <ref>       any git ref (commit/tag/branch). Sandbox is a detached worktree at it.
#                    OMIT for the current WORKING TREE (uncommitted edits included) — that
#                    path copies tracked + untracked-but-not-ignored files instead.
#   --env-root <dir> project under test (default: git top of CWD).
#
#   Build/test knobs (env vars):
#     PROBE_DRY_RUN=1  build + strip the sandbox and print what was removed, but do NOT
#                      invoke claude. Lets you verify the mechanics without spending tokens.
#     PROBE_KEEP=1     don't delete the sandbox on exit (its path is printed to stderr).
#
#   Exit 0 = an answer was produced (or the dry-run built cleanly); non-zero = couldn't run.
#
# RUN IT FROM A HUMAN SHELL. It launches `claude -p`; an agent in auto mode can't spawn that.
set -uo pipefail

scenario_file=""; out_dir=""; at_ref=""; env_root=""
while (( $# )); do
  case "$1" in
    --at)       at_ref="${2:?--at needs a git ref}"; shift 2 ;;
    --env-root) env_root="${2:?--env-root needs a dir}"; shift 2 ;;
    -*)         echo "probe-codebase: unknown flag $1" >&2; exit 64 ;;
    *)          if   [[ -z "$scenario_file" ]]; then scenario_file="$1";
                elif [[ -z "$out_dir"       ]]; then out_dir="$1";
                else echo "probe-codebase: unexpected arg $1" >&2; exit 64; fi; shift ;;
  esac
done

[[ -n "$scenario_file" && -n "$out_dir" ]] || {
  echo "usage: probe-codebase.sh <scenario-file> <out-dir> [--at <ref>] [--env-root <dir>]" >&2
  exit 64; }

die() { echo "probe-codebase: $*" >&2; exit 1; }
[[ "${PROBE_DRY_RUN:-0}" == "1" ]] || command -v claude >/dev/null 2>&1 || die "claude CLI not found."

env_root="${env_root:-$(git rev-parse --show-toplevel 2>/dev/null || true)}"
[[ -n "$env_root" ]] || die "not in a git repo and --env-root not given."
env_root="$(cd "$env_root" && pwd)"
[[ -f "$scenario_file" ]] || die "scenario file not found: $scenario_file."
scenario="$(cat "$scenario_file")"
[[ -z "$at_ref" ]] || git -C "$env_root" rev-parse --verify --quiet "$at_ref^{commit}" >/dev/null \
  || die "--at '$at_ref' is not a commit in $env_root."

# --- headless permission posture: harness default, then the env's committed override
#     (exactly how plan-in-isolation.sh / probe-expert.sh resolve it). ---
CLAUDE_PERM_ARGS=( --permission-mode auto )
# shellcheck disable=SC1091
[[ -f "$env_root/.harness/env" ]] && source "$env_root/.harness/env"

# --- build the sandbox: the codebase, at <ref> or from the working tree ---
sandbox="$(mktemp -d "${TMPDIR:-/tmp}/probe-codebase.XXXXXX")"
is_worktree=0
cleanup() {
  if [[ "${PROBE_KEEP:-0}" == "1" ]]; then echo "probe-codebase: kept sandbox $sandbox" >&2; return; fi
  (( is_worktree )) && git -C "$env_root" worktree remove --force "$sandbox" >/dev/null 2>&1
  rm -rf "$sandbox"
}
trap cleanup EXIT

if [[ -n "$at_ref" ]]; then
  # A real detached worktree — the codebase IS the thing under test, so it must be a real
  # checkout (not a synthesized tree) for agentic search to behave the way it does in anger.
  git -C "$env_root" worktree add --detach "$sandbox" "$at_ref" >/dev/null 2>&1 \
    || die "git worktree add failed at $at_ref."
  is_worktree=1
  echo "probe-codebase: sandbox = worktree at $at_ref" >&2
else
  # Working tree, uncommitted edits included. Copy tracked + untracked-but-not-ignored files
  # only, so build output and other gitignored junk never reaches the probe. `ls-files` can
  # name a file deleted from the worktree, hence the tolerant cp.
  while IFS= read -r -d '' f; do
    mkdir -p "$sandbox/$(dirname "$f")"
    cp -p "$env_root/$f" "$sandbox/$f" 2>/dev/null || true
  done < <(git -C "$env_root" ls-files --cached --others --exclude-standard -z)
  git -C "$sandbox" init -q >/dev/null 2>&1 || true   # a real project root aids agentic search
  echo "probe-codebase: sandbox = working tree copy" >&2
fi

# --- strip the PROSE levers, so only structure can answer ---
stripped=()
[[ -d "$sandbox/.claude/skills/expert" ]] && { rm -rf "$sandbox/.claude/skills/expert"; stripped+=(".claude/skills/expert"); }
while IFS= read -r -d '' f; do
  rm -f "$f"; stripped+=("${f#"$sandbox"/}")
done < <(find "$sandbox" -type f \( -name AGENTS.md -o -name CLAUDE.md \) -not -path '*/.git/*' -print0)
if (( ${#stripped[@]} )); then
  echo "probe-codebase: stripped prose levers — ${stripped[*]}" >&2
else
  echo "probe-codebase: WARNING — no Expert/AGENTS.md/CLAUDE.md found to strip; is --env-root right?" >&2
fi

mkdir -p "$out_dir"

# --- dry run: report the sandbox and stop (mechanics check, no tokens spent) ---
if [[ "${PROBE_DRY_RUN:-0}" == "1" ]]; then
  echo "probe-codebase: DRY RUN — sandbox at $sandbox" >&2
  echo "probe-codebase: remaining prose levers (must be EMPTY):" >&2
  ( cd "$sandbox" && find . -type f \( -name AGENTS.md -o -name CLAUDE.md \) -not -path './.git/*'; \
    [[ -d .claude/skills/expert ]] && echo .claude/skills/expert ) >&2
  exit 0
fi

# --- ask the localization question; capture the answer + a discoverable session id ---
sid="$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "noid-$$-$RANDOM")"
prompt="$(cat <<PROMPT
You are a fresh engineer picking up a task in this repository. You have the codebase and
NOTHING else — no project memory, no conventions document, no one to ask. Work only from
what you can see: file and folder names, structure, and the code's nearest neighbors.

Explore only as far as you need to answer confidently, then answer ONLY the task below.
Be concrete and name real paths. Your answer must state:

1. WHERE the change belongs — the exact file or folder, and why that location and not another.
2. WHAT PRECEDENT you would follow — the specific existing file you would copy the shape of,
   and why you trust it as the example to imitate.
3. WHICH CONSTRAINTS you inferred from the surrounding code, and what you were unsure about.

===== TASK =====
$scenario
PROMPT
)"

( cd "$sandbox" && claude -p --session-id "$sid" "${CLAUDE_PERM_ARGS[@]}" "$prompt" ) \
  > "$out_dir/answer.txt" 2> "$out_dir/claude.stderr" || true

[[ -s "$out_dir/answer.txt" ]] || die "no answer produced (see $out_dir/claude.stderr)."
echo "$sid" > "$out_dir/session-id"
echo "$out_dir"
