#!/usr/bin/env bash
# learn-dispatch.sh — one tick of the MEMORY loop for ONE environment.
#
# The post-merge memory update (/learn) used to be a dispatcher step, which made
# a multi-minute memory rebuild block every feature step. This script makes the
# memory update its OWN loop: its own supervisor schedule, its own lock, its own
# dedicated worktree. The two loops never block each other and coordinate only
# through git (Inv 1 + 7):
#   - refs/harness/last-learned — a single moving "watermark" ref recording how far
#     into main's history /learn has already digested. It lives in its own ref
#     namespace, so it survives learn/<sha> branch deletion and is shared across
#     nodes. We advance it with an atomic compare-and-swap (--force-with-lease).
#   - learn/<sha> + `git ls-remote` — per-merge idempotency, exactly as before.
#
# Tier 1 (harness repo) owned. Invoked by the context-specs CLI supervisor on its
# own interval (default 10m):
#
#   scripts/learn-dispatch.sh <env-path> [env-name]
#
# Exit contract: 0 = no-op/paused/done, nonzero = error (supervisor backs off).
# There is no exit-10 drain here — after a learn run, the open learn/<sha> PR
# pauses the loop until the human merges, so the next tick is a no-op anyway.
#
# See references/dispatcher-explained.md ("The memory loop") in
# skills/harness/env-init for the design and what is safe to change.

set -euo pipefail

# Prefer what we were told (the supervisor exports it), fall back to our own
# location — this script is vendored INTO the harness, so that is still correct
# when a human runs it by hand. See poll-and-dispatch.sh for why this matters.
CONTEXT_SPECS_HOME="${CONTEXT_SPECS_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export CONTEXT_SPECS_HOME
[[ -f "$CONTEXT_SPECS_HOME/.context-specs/manifest.json" ]] || {
  echo "learn-dispatch: CONTEXT_SPECS_HOME=$CONTEXT_SPECS_HOME is not a harness" >&2; exit 1; }
ENV_PATH="$(cd "${1:?usage: learn-dispatch.sh <env-path> [env-name]}" && pwd)"
ENV_NAME="${2:-$(basename "$ENV_PATH")}"
STATE_DIR="${STATE_DIR:-$CONTEXT_SPECS_HOME/state/$ENV_NAME}"
mkdir -p "$STATE_DIR"

# Serialize against concurrent learn ticks for THIS environment (a from-scratch
# Expert bootstrap can outlast the tick interval). Independent of the build
# loop's tick.lock — different file — so the two loops never wait on each
# other. (Inv 5)
exec {lockfd}>"$STATE_DIR/learn.lock"; flock -n "$lockfd" || exit 0

# Config the shared helpers need. Mirrors the dispatcher's block.
# CLAUDE_PERM_ARGS must be set ABOVE the .harness/env source so env can replace it.
WORKTREE_BASE="$(dirname "$ENV_PATH")/$(basename "$ENV_PATH")-harness"
CLAUDE_PERM_ARGS=( --permission-mode auto )
[[ -f "$ENV_PATH/.harness/env" ]] && source "$ENV_PATH/.harness/env"

# Shared helpers: worktree_for, bootstrap_worktree, run_claude,
# render_sessions_table, ghe.
source "$(dirname "${BASH_SOURCE[0]}")/harness-lib.sh"

LEARN_WT="$(worktree_for learn)"     # <env>-harness-learn sibling (persistent, reused)
WATERMARK_REF="refs/harness/last-learned"

# Post the headless session trail on the learn/<sha> PR so the human evaluating the
# memory changes can open the trace and see exactly what /learn read and why it routed
# each fact as it did. Reuses the shared render_sessions_table; framed for
# troubleshooting a memory decision. $feature is the per-sha session label (learn-<sha>)
# so the table shows exactly this run; $branch is learn/<sha>.
signal_learn_review() {
  local feature="$1" branch="$2"
  local body="$STATE_DIR/learn-review-body-${feature}.md"
  {
    echo "## /learn session — why memory changed"
    echo
    echo "These memory edits (Expert reference files, invariants, AGENTS.md pointers,"
    echo "candidate lints) were written by a headless \`/learn\` over the merged"
    echo "diff. If a routing call here looks wrong — a fact in the wrong surface,"
    echo "an overfit lint, an Expert reference file that says too much — open the trace"
    echo "below to see exactly what \`/learn\` read and how it decided, before you"
    echo "accept or revise it."
    echo
    echo "**Session** (open the trace at"
    echo "\`~/.claude/projects/<encoded>/<session-id>.jsonl\`):"
    echo
    render_sessions_table "$feature"
  } > "$body"
  ghe pr comment "$branch" --body-file "$body" 2>/dev/null || true
}

# Atomic compare-and-swap on the watermark: move it to $TO only if the remote is
# still at the value we read ($1, or the zero oid = "expect it not to exist" for the
# first run). A lost race (another node advanced it first) is fine — we just log and
# the next tick re-derives. This is the same first-to-push-wins primitive the
# dispatcher uses to claim PRDs. (Inv 7)
advance_watermark() {
  local expect="${1:-0000000000000000000000000000000000000000}"
  git -C "$ENV_PATH" push --quiet --force-with-lease="${WATERMARK_REF}:${expect}" \
    origin "${TO}:${WATERMARK_REF}" 2>/dev/null \
    || echo "learn-dispatch: watermark not advanced (another node won the race, or push failed)" >&2
}

# Fetch main + the watermark ref namespace. Fetch only touches refs/objects,
# never the environment's working tree. Explicit refspecs because refs/harness/*
# isn't in the default.
git -C "$ENV_PATH" fetch --quiet origin \
  '+refs/heads/*:refs/remotes/origin/*' \
  '+refs/harness/*:refs/harness/*' || true

# No remote / no main yet (e.g. a fresh-repo dry-run before origin exists) → nothing
# to do. Guard before anything reads origin/main.
git -C "$ENV_PATH" rev-parse --verify --quiet origin/main >/dev/null 2>&1 \
  || { echo "learn-dispatch: no origin/main yet — nothing to do." >&2; exit 0; }

# PAUSE while a learn PR is open: serialize memory edits behind human review so they
# stay linear and conflict-free. Nothing is queued and nothing is dropped — the
# backlog is implicit in (watermark, origin/main) and recomputed every tick. When the
# human merges the open learn PR, the next tick batches every merge that landed since.
# Checked early so a paused tick never even touches the learn worktree.
if ghe pr list --state open --json headRefName \
     --jq '.[] | select(.headRefName | startswith("learn/")) | .headRefName' \
     2>/dev/null | grep -q .; then
  exit 0
fi

# The diff range: from the durable watermark (or a bounded look-back on the very first
# run — a full from-scratch Expert is /learn --rebuild, a human action, not this loop)
# up to current main.
WATERMARK_OLD="$(git -C "$ENV_PATH" rev-parse --verify --quiet "${WATERMARK_REF}" 2>/dev/null || echo "")"
if [[ -n "$WATERMARK_OLD" ]]; then
  SINCE="$WATERMARK_OLD"
else
  SINCE="$(git -C "$ENV_PATH" rev-parse --verify --quiet 'origin/main~50^{commit}' 2>/dev/null \
           || git -C "$ENV_PATH" rev-list --max-parents=0 origin/main | tail -n1)"
fi
TO="$(git -C "$ENV_PATH" rev-parse origin/main)"

# Nothing new on main → no-op (don't even touch the watermark or the worktree).
[[ "$SINCE" == "$TO" ]] && exit 0

# Cross-node idempotency: if another node already pushed learn/<to>, don't duplicate
# it — just catch our watermark up and exit. (Inv 7)
if git -C "$ENV_PATH" ls-remote --exit-code origin "learn/${TO}" >/dev/null 2>&1; then
  advance_watermark "$WATERMARK_OLD"
  exit 0
fi

# There IS something to learn. Ensure the dedicated, reused learn worktree exists and
# is a clean, current main. Created once (with bootstrap, so a drafted lint and
# check-agents-md.sh can actually run) and reused every run — there is exactly one, so
# it's never torn down. `git worktree add` only writes the NEW path; it never touches
# the developer's working tree.
if [[ ! -d "$LEARN_WT" ]]; then
  git -C "$ENV_PATH" worktree add --quiet --detach "$LEARN_WT" origin/main \
    || { echo "learn-dispatch: could not create $LEARN_WT" >&2; exit 1; }
  bootstrap_worktree "$LEARN_WT"
fi
# The worktree is persistent but the tier-1 skill set is not frozen: re-link on
# every run so /learn always sees the current skills (idempotent, fast).
context-specs link "$LEARN_WT" >/dev/null 2>&1 || true
[[ -e "$LEARN_WT/.claude/skills/learn/SKILL.md" ]] \
  || echo "warn: tier-1 skills missing in $LEARN_WT after link — /learn will run context-less" >&2
# Per-run wipe (-fd keeps node_modules & bootstrapped deps, like the dispatcher's
# per-feature wipe), then put it on the learn/<to> branch off the clean main.
git -C "$LEARN_WT" checkout --quiet -f --detach origin/main
git -C "$LEARN_WT" clean -qfd
git -C "$LEARN_WT" checkout --quiet -B "learn/${TO}" origin/main

# Run /learn there. It reads SINCE..TO, writes memory, pushes learn/<to>, and opens
# the PR (it never auto-merges — the human steers at merge).
run_claude learn "learn-${TO}" 1 "$LEARN_WT" "/learn --since ${SINCE} --sha ${TO}"

# Surface this run's session on the learn PR (only if /learn actually opened one — a
# 0/3 no-op merge teaches nothing and opens no PR).
if ghe pr view "learn/${TO}" >/dev/null 2>&1; then
  signal_learn_review "learn-${TO}" "learn/${TO}"
fi

# Advance the watermark to TO whether or not a PR opened: a no-op merge is still
# "learned" and must not be re-examined every tick. A deterministic /learn failure
# is not retried here — the recovery path is a human `/learn --rebuild`.
advance_watermark "$WATERMARK_OLD"

# One-shot cleanup of this run's transient files — the session id now lives in the PR
# comment, and the watermark + ls-remote prevent a re-run.
rm -f "$STATE_DIR/sessions-learn-${TO}.tsv" "$STATE_DIR/learn-review-body-learn-${TO}.md"
