#!/usr/bin/env bash
# harvest-eval-inputs.sh — list merged features usable as long-term-memory eval fixtures.
#
# For each prds/<feature>/ that has BOTH prd.md and run-prd-test.sh, find the
# first-parent commit on the main branch that introduced it (the merge that landed
# the feature). Features whose PR is still OPEN are skipped when `gh` is available
# (a still-in-flight feature isn't history yet); without `gh`, everything is listed.
#
# Run at the project root. Output (one line per feature, tab-separated):
#   <feature>\t<landing_sha>\t<prd_path>\t<runner_path>
#
# The eval fixture wants the MERGE-PARENT (the code as it was before the feature
# landed): use `git rev-parse <landing_sha>^` on the sha this prints.
#
# Exit 0 if at least one row was emitted; 2 if none.

set -euo pipefail

MAIN_BRANCH="${MAIN_BRANCH:-main}"

if ! git rev-parse --verify --quiet "$MAIN_BRANCH" >/dev/null; then
  echo "no '$MAIN_BRANCH' branch here — run at the project root (or set MAIN_BRANCH)" >&2
  exit 64
fi

have_gh=0
command -v gh >/dev/null 2>&1 && have_gh=1

rows=0
for prd_dir in prds/*/; do
  [[ -d "$prd_dir" ]] || continue
  feature="$(basename "$prd_dir")"
  prd="prds/$feature/prd.md"
  runner="prds/$feature/run-prd-test.sh"
  [[ -f "$prd" && -f "$runner" ]] || continue

  # First first-parent commit on main touching this PRD dir = the commit that landed it.
  sha="$(git log --first-parent --reverse --format=%H "$MAIN_BRANCH" -- "prds/$feature" | head -n 1)"
  [[ -n "$sha" ]] || continue   # committed but never landed on main

  # Skip features still in flight (open PR) — degrade gracefully without gh.
  if (( have_gh )); then
    state="$(gh pr view "feature/$feature" --json state --jq '.state' 2>/dev/null || true)"
    [[ "$state" == "OPEN" ]] && continue
  fi

  printf '%s\t%s\t%s\t%s\n' "$feature" "$sha" "$prd" "$runner"
  rows=$((rows + 1))
done

if (( rows == 0 )); then
  echo "no harvestable features (need prds/<f>/{prd.md,run-prd-test.sh} landed on $MAIN_BRANCH)" >&2
  exit 2
fi
