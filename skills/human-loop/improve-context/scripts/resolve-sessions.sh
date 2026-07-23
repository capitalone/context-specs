#!/usr/bin/env bash
# resolve-sessions.sh — turn a PR (or feature) into its build-trail session IDs + local trace paths.
#
# The session table is posted on the PR DETERMINISTICALLY BY THE DISPATCHER
# (render_sessions_table -> signal_human_review / signal_stuck / signal_learn_review,
# each ending in `gh pr comment`). That comment is the durable artifact — the local
# The harness repo's state/<env>/sessions-<f>.tsv is ephemeral and rm -f'd on PR cleanup, so we never read it.
#
# Output (one line per session, tab-separated):
#   <session_id>\t<jsonl_path|MISSING>
# Exit 0 if at least one session ID was found; 2 if none (likely no harness comment on the PR).
#
# Usage:
#   resolve-sessions.sh <PR#>
#   resolve-sessions.sh <feature>        # resolves to the PR on feature/<feature> (or learn/<feature>)
#   resolve-sessions.sh <branch>         # any branch name gh recognizes

set -euo pipefail

ARG="${1:-}"
if [[ -z "$ARG" ]]; then
  echo "usage: resolve-sessions.sh <PR#|feature|branch>" >&2
  exit 64
fi

PROJECTS_DIR="${CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}"

# --- Resolve a PR number from the argument -----------------------------------
pr=""
if [[ "$ARG" =~ ^[0-9]+$ ]]; then
  pr="$ARG"
else
  # Try the raw branch, then the harness-conventional prefixes.
  for head in "$ARG" "feature/$ARG" "learn/$ARG"; do
    pr="$(gh pr list --head "$head" --state all --json number --jq '.[0].number // empty' 2>/dev/null || true)"
    [[ -n "$pr" ]] && break
  done
fi
if [[ -z "$pr" ]]; then
  echo "could not resolve a PR from '$ARG' (tried as PR#, then heads: $ARG, feature/$ARG, learn/$ARG)" >&2
  exit 65
fi

# --- Pull every comment body and extract session IDs from the session table --
# Table rows look like: | <time> | `<step>` | <attempt> | `<session_id>` | <exit> |
# session_id is the 5th pipe-delimited field, backtick-wrapped. The header row
# ("| Time | Step | Attempt | Session ID | Exit |") has no backticks in that field,
# so filtering on a backtick in field 5 skips it cleanly.
bodies="$(gh pr view "$pr" --json comments --jq '.comments[].body' 2>/dev/null || true)"
if [[ -z "$bodies" ]]; then
  echo "PR #$pr has no comments — no session table to read" >&2
  exit 2
fi

mapfile -t ids < <(
  printf '%s\n' "$bodies" \
    | awk -F'|' 'NF>=6 && $5 ~ /`/ { gsub(/[` ]/,"",$5); if ($5 != "") print $5 }' \
    | awk '!seen[$0]++'
)

if [[ ${#ids[@]} -eq 0 ]]; then
  echo "PR #$pr has comments but no harness session table (no backtick-wrapped session IDs found)" >&2
  exit 2
fi

# --- Map each ID to its local JSONL trace (glob dodges the project-path encoding) ---
shopt -s nullglob
for id in "${ids[@]}"; do
  matches=("$PROJECTS_DIR"/*/"$id".jsonl)
  if [[ ${#matches[@]} -gt 0 ]]; then
    printf '%s\t%s\n' "$id" "${matches[0]}"
  else
    printf '%s\tMISSING\n' "$id"
  fi
done
