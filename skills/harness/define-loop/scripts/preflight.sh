#!/usr/bin/env bash
# preflight.sh — deterministic readiness report for /define-loop.
# Prints a checklist; does NOT gate. The skill reads this and decides what to do.
# Run from the consumer project's root (the human's checkout).
#
# Usage: scripts/preflight.sh [namespace]
#   Pass the intended namespace (e.g. "bug") to also get a re-run / collision check
#   for that specific loop.

NS="${1:-}"
ok()   { printf '  [ok]   %s\n' "$1"; }
warn() { printf '  [warn] %s\n' "$1"; }
miss() { printf '  [MISS] %s\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

echo "=== Environment ==="
if git rev-parse --git-dir >/dev/null 2>&1; then
  ok "git repository"
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")
  [[ "$branch" == "main" || "$branch" == "master" ]] && ok "on $branch" || warn "on '$branch' (expected main)"
  git diff --quiet && git diff --cached --quiet 2>/dev/null && ok "working tree clean" || warn "working tree has uncommitted changes"
  git remote get-url origin >/dev/null 2>&1 && ok "origin remote: $(git remote get-url origin 2>/dev/null)" || miss "no 'origin' remote (needed for branch-as-queue)"
  echo "  derived slug: $(git config user.email 2>/dev/null | cut -d@ -f1)"
else
  miss "not a git repository"
fi
have gh     && { gh auth status >/dev/null 2>&1 && ok "gh CLI (authenticated)" || warn "gh CLI present but not authenticated (gh auth login)"; } || miss "gh CLI (needed for PR ops)"
have claude && ok "claude CLI" || warn "claude CLI not on PATH (the dispatcher shells out to 'claude -p')"

echo
echo "=== Base harness (define-loop EXTENDS an initialized harness — run /harness-init first if missing) ==="
[[ -f .harness/env ]]                  && ok ".harness/env"                  || miss ".harness/env (run /harness-init)"
[[ -f scripts/poll-and-dispatch.sh ]]  && ok "scripts/poll-and-dispatch.sh"  || miss "scripts/poll-and-dispatch.sh (run /harness-init)"
[[ -f scripts/harness-lib.sh ]]        && ok "scripts/harness-lib.sh (shared; the new loop sources it)" || miss "scripts/harness-lib.sh (run /harness-init)"
[[ -f scripts/harness-tick.sh ]]       && ok "scripts/harness-tick.sh"       || warn "scripts/harness-tick.sh absent"
base="../$(basename "$PWD")-harness"
[[ -d "$base" ]] && ok "build-loop host worktree $base" || warn "host worktree $base absent (build loop may not be running yet)"

echo
echo "=== Skills the new loop wires (reused unchanged from the catalog) ==="
SK=.claude/skills
for s in intent spec-planning spec-validate implement-mainspec fix-local-checks address-feedback; do
  if find "$SK" -type f -path "*/$s/SKILL.md" 2>/dev/null | grep -q . ; then ok "/$s"
  else miss "/$s (install from the catalog before the loop runs end to end)"; fi
done
# /intent is the clone source for the generated minter's runner-recipes + right-reason refs.
find "$SK" -type f -path "*/intent/references/runner-recipes.md" 2>/dev/null | grep -q . \
  && ok "intent references present (minter clones runner-recipes.md + right-reason.md from them)" \
  || warn "intent references not found — generated minter will need those two refs authored by hand"

echo
echo "=== This namespace (re-run / collision check) ==="
if [[ -z "$NS" ]]; then
  warn "no namespace passed — re-run as 'scripts/preflight.sh <namespace>' for a per-loop check"
else
  [[ -f "scripts/${NS}-dispatch.sh" ]] && warn "scripts/${NS}-dispatch.sh exists (re-run? will diff)" || ok "scripts/${NS}-dispatch.sh absent (fresh)"
  [[ -f "scripts/${NS}-tick.sh" ]]     && warn "scripts/${NS}-tick.sh exists (re-run?)"               || ok "scripts/${NS}-tick.sh absent (fresh)"
  [[ -d "loops/${NS}" ]]               && warn "loops/${NS}/ exists (re-run? will diff)"              || ok "loops/${NS}/ absent (fresh)"
  [[ -d ".claude/skills/intent-${NS}" ]] && warn ".claude/skills/intent-${NS}/ exists (re-run?)"      || ok "minter /intent-${NS} absent (fresh)"
  nsbase="../$(basename "$PWD")-harness-ns-${NS}"
  [[ -d "$nsbase" ]] && warn "infra worktree $nsbase already exists" || ok "infra worktree $nsbase absent (fresh)"
  # Collision guard: a build-loop feature literally named "$NS" would live at
  # ../<repo>-harness-$NS; our infra worktree uses the -ns- infix to avoid it.
  [[ -d "../$(basename "$PWD")-harness-${NS}" ]] && warn "note: build-loop worktree ../$(basename "$PWD")-harness-${NS} exists (a feature named '${NS}') — the -ns- infix keeps us clear of it" || true
fi

echo
echo "Preflight complete. [MISS] items block; [warn] items need a decision."
