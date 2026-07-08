#!/usr/bin/env bash
# harvest-eval-inputs.sh — list merged features usable as long-term-memory eval cases,
# with the git shas a case needs. No manual archaeology.
#
# A long-term-memory case re-plans a merged feature at its PRE-PLAN checkout with today's
# Expert and compares against the plan that ACTUALLY SHIPPED. Both plans, and the code diff,
# already exist in history. For each prds/<feature>/ that has BOTH prd.md and run-prd-test.sh
# AND a distinct spec-planning commit, this prints (tab-separated):
#
#   <feature> \t <preplan_sha> \t <oldplan_sha> \t <tip_sha> \t <landing_sha>
#
#   preplan_sha (A)  the commit to RE-PLAN against: prds/<f>/ present, specs/<f>/ ABSENT.
#                    Computed as the parent of the mainspec-Add commit, so it is robust to
#                    a PRD commit that also touched incidental files (roadmap, eslint, …).
#   oldplan_sha (B)  the commit that first ADDED specs/<f>/mainspec.md — the baseline plan.
#                    `git show <B>:specs/<f>/mainspec.md` (+ slices/) is the old plan.
#   tip_sha          the feature-branch tip (merge^2 for a merge commit, else landing).
#   landing_sha      the first-parent commit on <main> that landed the feature.
#
#   Code diff (C), for seeding the rubric — what actually shipped:
#     git diff <preplan_sha> <tip_sha> -- ':(exclude)prds/**' ':(exclude)specs/**'
#
# The PRD + runner are at prds/<feature>/{prd.md,run-prd-test.sh} by convention.
#
# Run at the project root. Exit 0 if at least one row was emitted; 2 if none.
#
# Features whose /intent + /spec-planning were SQUASHED into one commit (no distinct
# mainspec-Add whose parent still carries the PRD) are skipped with a note on stderr —
# they can't be a case as-is. Open-PR features are skipped when `gh` is available.

set -uo pipefail

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
  landing="$(git log --first-parent --reverse --format=%H "$MAIN_BRANCH" -- "prds/$feature" | head -n 1)"
  [[ -n "$landing" ]] || continue   # committed but never landed on main

  # Skip features still in flight (open PR) — degrade gracefully without gh.
  if (( have_gh )); then
    state="$(gh pr view "feature/$feature" --json state --jq '.state' 2>/dev/null || true)"
    [[ "$state" == "OPEN" ]] && continue
  fi

  # (B) old-plan sha: earliest commit reachable from landing that ADDED the mainspec. For a
  # merge-commit landing this reaches the feature branch's real spec-planning commit; for a
  # squash it resolves to the squash commit itself (caught by the (A) guard below).
  oldplan="$(git log --reverse --diff-filter=A --format=%H "$landing" -- "specs/$feature/mainspec.md" | head -n 1)"
  if [[ -z "$oldplan" ]]; then
    echo "skip $feature: no spec-planning commit that added specs/$feature/mainspec.md" >&2
    continue
  fi

  # (A) pre-plan sha = parent of (B). Guard: it must still carry the PRD and NOT yet carry
  # the spec — otherwise the history was squashed and this feature can't be a case as-is.
  preplan="$(git rev-parse --verify --quiet "${oldplan}^" || true)"
  if [[ -z "$preplan" ]] \
     || ! git cat-file -e "${preplan}:prds/$feature/prd.md" 2>/dev/null \
     || git ls-tree "$preplan" "specs/$feature" | grep -q .; then
    echo "skip $feature: no clean pre-plan commit (PRD present, spec absent) — squashed history?" >&2
    continue
  fi

  # Feature-branch tip for the code diff: merge^2 when landing is a 2-parent merge, else landing.
  tip="$(git rev-parse --verify --quiet "${landing}^2" || echo "$landing")"

  printf '%s\t%s\t%s\t%s\t%s\n' "$feature" "$preplan" "$oldplan" "$tip" "$landing"
  rows=$((rows + 1))
done

if (( rows == 0 )); then
  echo "no harvestable features (need prds/<f>/{prd.md,run-prd-test.sh} landed on $MAIN_BRANCH with a distinct spec-planning commit)" >&2
  exit 2
fi
