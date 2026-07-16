#!/usr/bin/env bash
# probe-expert.sh — invoke this project's /expert memory skill IN ISOLATION on one
# planning question, and capture the answer + its (discoverable) session id. The Tier-1
# engine behind evals/expert/ cases: "does the Expert's routing + content steer the plan?"
#
# It builds a MINIMAL SANDBOX — a throwaway dir containing ONLY `.claude/skills/expert`
# (a copy of the env's CURRENT working-tree Expert), nothing else — cd's in, and runs one
# `claude -p` that consults /expert and answers the planning question. Because NO codebase
# is present, the without-shard arm is HERMETIC: with the shard removed there is nothing on
# disk to leak it back, so a NEUTRAL verdict means the model already knew it, not that it
# peeked. (The "what happens in a full plan, with the codebase" question is Tier 2 —
# plan-in-isolation.sh.)
#
#   Usage:
#     probe-expert.sh <scenario-file> <out-dir> [BASELINE] [--env-root <dir>]
#
#   BASELINE — pick AT MOST ONE; omit it for the full-context "with-shard" arm (arm A):
#     --without <relpath>                 arm B (with/without): remove references/<shard>.md,
#                                         strike its routing-table row, AND strip inbound
#                                         references to it from sibling shards, so the shard
#                                         looks like it was cleanly deleted.
#     --prev <relpath> --prev-from <src>  arm B (version-vs-version): replace
#                                         references/<shard>.md with an OLDER version, keeping
#                                         its routing row (routing cancels; the wording delta
#                                         is what's judged). <src> is EITHER an existing file
#                                         OR a git ref (resolved as `git show <ref>:<path>`).
#
#   <scenario-file>  a planning question (the eval fixture's scenario.md).
#   <out-dir>        created; receives answer.txt + session-id; printed on success.
#   --env-root <dir> project whose working-tree Expert is under test (default: git top of CWD).
#   <relpath>        is relative to the Expert skill root, e.g.
#                    `references/invariant-timezone-safe-dates.md`.
#
#   Build/test knobs (env vars):
#     PROBE_DRY_RUN=1  build + transform the sandbox and print its file tree, but do NOT
#                      invoke claude. Lets you verify the mechanics without spending tokens.
#     PROBE_KEEP=1     don't delete the sandbox on exit (its path is printed to stderr).
#
#   Exit 0 = an answer was produced (or the dry-run built cleanly); non-zero = couldn't run.
#
# RUN IT FROM A HUMAN SHELL. It launches `claude -p`; an agent in auto mode can't spawn that.
set -uo pipefail

scenario_file=""; out_dir=""; without=""; prev=""; prev_from=""; env_root=""
while (( $# )); do
  case "$1" in
    --without)   without="${2:?--without needs a relpath}"; shift 2 ;;
    --prev)      prev="${2:?--prev needs a relpath}"; shift 2 ;;
    --prev-from) prev_from="${2:?--prev-from needs a ref or path}"; shift 2 ;;
    --env-root)  env_root="${2:?--env-root needs a dir}"; shift 2 ;;
    -*)          echo "probe-expert: unknown flag $1" >&2; exit 64 ;;
    *)           if   [[ -z "$scenario_file" ]]; then scenario_file="$1";
                 elif [[ -z "$out_dir"       ]]; then out_dir="$1";
                 else echo "probe-expert: unexpected arg $1" >&2; exit 64; fi; shift ;;
  esac
done

[[ -n "$scenario_file" && -n "$out_dir" ]] || {
  echo "usage: probe-expert.sh <scenario-file> <out-dir> [--without <relpath> | --prev <relpath> --prev-from <src>] [--env-root <dir>]" >&2
  exit 64; }
[[ -z "$without" || -z "$prev" ]] || { echo "probe-expert: --without and --prev are mutually exclusive" >&2; exit 64; }
[[ -z "$prev" || -n "$prev_from" ]] || { echo "probe-expert: --prev requires --prev-from <ref|path>" >&2; exit 64; }
[[ -z "$prev_from" || -n "$prev" ]] || { echo "probe-expert: --prev-from requires --prev <relpath>" >&2; exit 64; }

die() { echo "probe-expert: $*" >&2; exit 1; }
[[ "${PROBE_DRY_RUN:-0}" == "1" ]] || command -v claude >/dev/null 2>&1 || die "claude CLI not found."

env_root="${env_root:-$(git rev-parse --show-toplevel 2>/dev/null || true)}"
[[ -n "$env_root" ]] || die "not in a git repo and --env-root not given."
env_root="$(cd "$env_root" && pwd)"
expert_src="$env_root/.claude/skills/expert"
[[ -d "$expert_src" ]] || die "no Expert at $expert_src."
[[ -f "$scenario_file" ]] || die "scenario file not found: $scenario_file."
expert_rel="${expert_src#"$env_root"/}"                      # e.g. .claude/skills/expert
scenario="$(cat "$scenario_file")"

# --- headless permission posture: harness default, then the env's committed override
#     (exactly how plan-in-isolation.sh / the dispatcher resolve it). ---
CLAUDE_PERM_ARGS=( --permission-mode auto )
# shellcheck disable=SC1091
[[ -f "$env_root/.harness/env" ]] && source "$env_root/.harness/env"

# --- build the minimal sandbox: ONLY .claude/skills/expert, from the working tree ---
sandbox="$(mktemp -d "${TMPDIR:-/tmp}/probe-expert.XXXXXX")"
cleanup() {
  if [[ "${PROBE_KEEP:-0}" == "1" ]]; then echo "probe-expert: kept sandbox $sandbox" >&2; return; fi
  rm -rf "$sandbox"
}
trap cleanup EXIT

mkdir -p "$sandbox/.claude/skills"
cp -R "$expert_src" "$sandbox/.claude/skills/expert"
git -C "$sandbox" init -q >/dev/null 2>&1 || true          # a real project root aids skill discovery
expert_sb="$sandbox/.claude/skills/expert"

# --- apply the baseline transform to the sandbox's Expert copy ---
if [[ -n "$without" ]]; then
  [[ -e "$expert_sb/$without" ]] || die "--without target not in Expert: $without"
  rm -f "$expert_sb/$without"
  base="$(basename "$without" .md)"                  # kebab-case slug; safe inside an ERE
  # 1. strike the shard's routing-table ROW from SKILL.md — remove the whole line, not just
  #    the link, so no half-row is left dangling in the table.
  if [[ -f "$expert_sb/SKILL.md" ]] && grep -qF "[[$base]]" "$expert_sb/SKILL.md"; then
    grep -vF "[[$base]]" "$expert_sb/SKILL.md" > "$expert_sb/SKILL.md.tmp" \
      && mv "$expert_sb/SKILL.md.tmp" "$expert_sb/SKILL.md"
  fi
  # 2. strip INBOUND references to the shard from the remaining shard bodies, modelling a
  #    CLEAN deletion (the Expert's "reconcile, don't accumulate" doctrine fixes inbound refs
  #    on delete). Remove the common cross-reference wrappers whole — "(see [[X]])",
  #    "— see [[X]]" — so no named-but-missing reference tells the baseline "a shard should
  #    exist here" (it would otherwise recommend writing it). De-link any remaining [[X]] as
  #    a fallback. Sibling PROSE that independently states the rule is left INTACT: that
  #    redundancy is a real, delete-relevant signal, not a leak to scrub.
  while IFS= read -r -d '' f; do
    sed -i -E \
      -e "s/ *\(see \[\[$base\]\]\)//g" \
      -e "s/ *— see \[\[$base\]\]//g" \
      -e "s/ *-- see \[\[$base\]\]//g" \
      -e "s/,? *see \[\[$base\]\]//g" \
      -e "s/\[\[$base\|([^]]*)\]\]/\1/g" \
      -e "s/\[\[$base\]\]/$base/g" \
      "$f"
  done < <(find "$expert_sb" -type f -name '*.md' -print0)
  echo "probe-expert: removed $without (struck routing row + stripped inbound refs to [[$base]])" >&2
elif [[ -n "$prev" ]]; then
  [[ -e "$expert_sb/$prev" ]] || die "--prev target not in Expert: $prev (a NEW shard has no prior version — use --without)"
  if [[ -f "$prev_from" ]]; then
    cp "$prev_from" "$expert_sb/$prev"
    echo "probe-expert: replaced $prev with file $prev_from" >&2
  else
    git -C "$env_root" show "$prev_from:$expert_rel/$prev" > "$expert_sb/$prev" 2>/dev/null \
      || die "--prev-from '$prev_from' is neither an existing file nor a git ref holding $expert_rel/$prev"
    echo "probe-expert: replaced $prev with $prev_from:$expert_rel/$prev" >&2
  fi
fi

mkdir -p "$out_dir"

# --- dry run: show the sandbox and stop (mechanics check, no tokens spent) ---
if [[ "${PROBE_DRY_RUN:-0}" == "1" ]]; then
  echo "probe-expert: DRY RUN — sandbox at $sandbox" >&2
  ( cd "$sandbox" && find .claude -type f | sort ) >&2
  exit 0
fi

# --- invoke /expert in isolation; capture the answer + a discoverable session id ---
sid="$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "noid-$$-$RANDOM")"
prompt="$(cat <<PROMPT
You are helping plan a feature for an existing project. You do NOT have the codebase in
front of you — rely on this project's long-term memory and your general knowledge.

FIRST: consult the \`expert\` skill (this project's long-term memory). Scan its routing
table and open ONLY the reference files whose USE WHEN matches the task. Do not page
through everything.

THEN: answer ONLY the single planning question at the end of the task below. Be concrete
about the exact operations you would perform.

===== TASK =====
$scenario
PROMPT
)"

( cd "$sandbox" && claude -p --session-id "$sid" "${CLAUDE_PERM_ARGS[@]}" "$prompt" ) \
  > "$out_dir/answer.txt" 2> "$out_dir/claude.stderr" || true

[[ -s "$out_dir/answer.txt" ]] || die "no answer produced (see $out_dir/claude.stderr).
   If the error mentions the 'expert' skill was not found, skill discovery from the bare
   sandbox failed — fall back to a fuller checkout (see plan-in-isolation.sh)."
echo "$sid" > "$out_dir/session-id"
echo "$out_dir"
