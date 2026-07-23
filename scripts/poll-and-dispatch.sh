#!/usr/bin/env bash
# poll-and-dispatch.sh — one tick of the harness outer loop.
#
# Deterministic bash. NO LLM in the decision path. The if/elif chain in the
# advance loop IS the state machine; the artifacts on disk ARE the state.
# Every section maps to one of the harness's load-bearing invariants — when this
# script and the prose disagree, the invariants win.
#
# Tier 1 (harness repo) owned. Invoked by the context-specs CLI (`start`/`run`)
# with the target environment as an argument:
#
#   scripts/poll-and-dispatch.sh <env-path> [env-name]
#
# It operates on the environment repo via `git -C` (refs, fetches, pushes, and
# sibling worktrees — never the developer's working tree) and keeps all runtime
# state under <harness-repo>/state/<env-name>/. Exit code contract:
#   0  — idle: no transitions this tick (includes STUCK-only ticks)
#   10 — advanced: at least one transition; the supervisor re-invokes immediately
#   *  — error: the supervisor backs off
#
# See the dispatcher-explained.md reference in skills/harness/env-init for what
# each section does and what is safe to change.

set -euo pipefail

# Prefer what we were told (the supervisor exports it), fall back to our own
# location — this script is vendored INTO the harness, so that is still correct
# when a human runs it by hand. Never let node and bash disagree: a split root
# means state/ splits, and the tick.lock flock below stops serializing anything.
CONTEXT_SPECS_HOME="${CONTEXT_SPECS_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export CONTEXT_SPECS_HOME                 # bootstrap-worktree.sh's link header consumes this
[[ -f "$CONTEXT_SPECS_HOME/.context-specs/manifest.json" ]] || {
  echo "poll-and-dispatch: CONTEXT_SPECS_HOME=$CONTEXT_SPECS_HOME is not a harness" >&2; exit 1; }
ENV_PATH="$(cd "${1:?usage: poll-and-dispatch.sh <env-path> [env-name]}" && pwd)"
ENV_NAME="${2:-$(basename "$ENV_PATH")}"
STATE_DIR="${STATE_DIR:-$CONTEXT_SPECS_HOME/state/$ENV_NAME}"
mkdir -p "$STATE_DIR"
TRANSITIONS=0

# Serialize against concurrent ticks for THIS environment only. Per-env lock
# file, not $0 — the script is shared by every environment now. (Inv 5)
exec {lockfd}>"$STATE_DIR/tick.lock"; flock -n "$lockfd" || exit 0

# Reserve exit code 10 for the explicit "advanced" exit at the bottom: if a
# failing command happens to exit 10, report a plain error (1) so the supervisor
# backs off instead of hot-draining.
trap '[[ $? -eq 10 ]] && exit 1' ERR

SLUG="$(git -C "$ENV_PATH" config user.email | cut -d@ -f1)"
WATCH="${WATCH_PATTERN:-prd/${SLUG}/*}"
# Per Inv 3 each in-flight feature gets its own ephemeral sibling worktree at
# '<env>-harness-<feature>', hanging off the developer's own clone. Overridable
# from the env's committed .harness/env (sourced below).
WORKTREE_BASE="$(dirname "$ENV_PATH")/$(basename "$ENV_PATH")-harness"
MAX_WORKTREES="${MAX_WORKTREES:-1}"
PLANNING_CAP="${PLANNING_CAP:-2}"         # /spec-planning retries before STUCK
VALIDATE_CAP="${VALIDATE_CAP:-2}"         # /spec-validate retries before STUCK
IMPLEMENT_CAP="${IMPLEMENT_CAP:-3}"       # PRD-runner retries before STUCK (the plan may be wrong)
LOCAL_CHECKS_CAP="${LOCAL_CHECKS_CAP:-2}" # local-checks two-strike (auto-fix → focused LLM fix → STUCK)
FEEDBACK_CAP="${FEEDBACK_CAP:-5}"         # reviewer feedback rounds before STUCK
# Convergence signal. When the reviewer has no Important findings left,
# REVIEW.md tells it to post a PR comment containing this marker. The dispatcher
# sees the marker and hands the PR to the human for /evaluate-pr. Uniform across
# reviewers (managed or self-hosted) — both can post a comment. If the reviewer
# never emits it, the feedback loop just runs to FEEDBACK_CAP and STUCKs (a clean
# PR the human merges) — acceptable degradation, no special case. Set the marker
# to EMPTY in .harness/env when there is no reviewer (converge at PR-open instead).
REVIEW_CLEAN_MARKER="${REVIEW_CLEAN_MARKER:-HARNESS_REVIEW_CLEAN}"

# Headless permission posture for `claude -p`. A headless session cannot show a
# permission prompt — without a posture, tool calls are denied, the skill can't
# do its work, and the step falsely STUCKs. `auto` is classifier-gated and
# prompt-free; on repeated classifier blocks the session aborts -> non-zero exit
# -> the step's retry/STUCK machinery catches it. Override in .harness/env, e.g.
#   CLAUDE_PERM_ARGS=( --dangerously-skip-permissions )
# if the CLI is Bedrock/Vertex-backed (auto is Anthropic-API only), the installed
# claude predates --permission-mode, or you want classifier-free, zero-overhead
# runs inside the isolated worktree. Set ABOVE the source line so .harness/env
# can replace the array.
CLAUDE_PERM_ARGS=( --permission-mode auto )

# Load the environment's committed config if present (MAX_WORKTREES,
# WATCH_PATTERN, CLAUDE_PERM_ARGS, ...).
[[ -f "$ENV_PATH/.harness/env" ]] && source "$ENV_PATH/.harness/env"

# Shared helpers (worktree_for, bootstrap_worktree, run_claude,
# render_sessions_table, ghe) live in harness-lib.sh — the memory loop
# (learn-dispatch.sh) uses the same ones, so they're factored out to avoid drift.
# They read the config globals set above (ENV_PATH, STATE_DIR, CLAUDE_PERM_ARGS,
# WORKTREE_BASE); bash resolves those at call time.
source "$(dirname "${BASH_SOURCE[0]}")/harness-lib.sh"

# Invariant 2: a feature/<f> is harness-owned iff prds/<f>/prd.md is committed
# to it. Hand-pushed feature/quickfix without a PRD is ignored.
has_prd() {
  git -C "$ENV_PATH" cat-file -e "origin/feature/${1}:prds/${1}/prd.md" 2>/dev/null
}

# Convergence handoff: the reviewer reported no Important findings, so
# the PR is the human's to evaluate. Post the session trail with an invitational
# framing (NOT a failure — this is the healthy terminal state of the review loop).
# Deterministic and once (the human-review-posted-<f> marker prevents re-posting).
signal_human_review() {
  local feature="$1" branch="feature/${feature}"
  local body="$STATE_DIR/human-review-body-${feature}.md"
  {
    echo "## Ready for your review"
    echo
    echo "The reviewer reports no outstanding Important findings. This PR is now"
    echo "yours to **evaluate** — run \`/evaluate-pr ${feature}\` to walk the change,"
    echo "run it locally, and build a firm understanding before you merge"
    echo "(\`/improve-context ${feature}\` if you'd rather audit *how* it was built)."
    echo
    echo "**Build sessions** (the full \`claude -p\` trail — open a trace at"
    echo "\`~/.claude/projects/<encoded>/<session-id>.jsonl\` to see what each agent"
    echo "saw and concluded; useful if you decide *not* to merge and want to find"
    echo "which context shaped a decision):"
    echo
    render_sessions_table "$feature"
  } > "$body"
  ghe pr comment "$branch" --body-file "$body" 2>/dev/null || true
}

# Signal STUCK to the human via the PR. Opens a draft PR if none exists yet
# (planning/validate can STUCK before any PR is open). Body includes the step,
# the cap, the per-feature session log (failing step + upstream chain), an
# optional tail of failing output, and a pointer to /improve-context. The PR is
# the single human-facing surface; nothing else is captured to disk for the human.
signal_stuck() {
  local feature="$1" step="$2" cap="$3" output_file="${4:-}"
  touch "$STATE_DIR/stuck-${feature}"
  local branch="feature/${feature}"
  local body="$STATE_DIR/stuck-body-${feature}.md"
  {
    echo "## STUCK — your turn"
    echo
    echo "**Step:** \`/${step}\` — cap reached after ${cap} attempts."
    echo
    echo "**Sessions** (failing step + upstream chain — open the trace files in"
    echo "\`~/.claude/projects/<encoded-project>/<session-id>.jsonl\` to see what"
    echo "the agent saw and concluded; for a CI/server harness, your project should"
    echo "upload these as workflow artifacts):"
    echo
    if [[ -f "$STATE_DIR/sessions-${feature}.tsv" ]]; then
      render_sessions_table "$feature"
      echo
    fi
    if [[ -s "$output_file" ]]; then
      echo "**Last 30 lines of failing output:**"
      echo
      echo '```'
      tail -n 30 "$output_file"
      echo '```'
      echo
    fi
    echo "## Next step: /improve-context"
    echo
    echo "Diagnosis-first: the context that misled the agent gets fixed before the code."
    echo "In the project repo, run:"
    echo
    echo '```'
    echo "claude"
    echo "> /improve-context ${feature}"
    echo '```'
    echo
    echo "It reads these sessions with you, finds the context defect, fixes it on this"
    echo "branch, then the code — the merge carries both and \`/learn\` picks them up."
  } > "$body"
  if ghe pr view "$branch" >/dev/null 2>&1; then
    ghe pr comment "$branch" --body-file "$body" 2>/dev/null || true
  else
    ghe pr create --base main --head "$branch" --draft \
                 --title "STUCK: ${feature} (${step})" --body-file "$body" 2>/dev/null || true
  fi
}

# Has the reviewer signalled "done"? True iff any PR comment contains the marker.
# Dead simple on purpose: see the marker, converge. We don't check freshness — if
# a later push lands after the marker, it came from the human (the loop is halted
# in HUMAN_REVIEW by then), and the human handles whatever the reviewer says about
# it. Deterministic, one gh call, no LLM. Empty marker = no reviewer (handled at
# PR-open), so this returns false.
reviewer_converged() {
  local branch="$1"
  [[ -n "$REVIEW_CLEAN_MARKER" ]] || return 1
  # NB: gh's --jq is a lightweight filter, NOT full jq — it has no --arg. The
  # prior `--jq --arg m "$MARKER" '<expr>'` form made gh treat --arg/m/marker/expr
  # as stray positional args ("accepts at most 1 arg(s)"), so it errored, 2>/dev/null
  # hid it, and this ALWAYS returned false — the HUMAN_REVIEW handoff never fired and
  # every PR ground to FEEDBACK_CAP and false-STUCK. Pull the comment bodies and
  # fixed-string match the marker in the shell instead.
  ghe pr view "$branch" --json comments --jq '.comments[]?.body' 2>/dev/null \
    | grep -qF "$REVIEW_CLEAN_MARKER"
}

git -C "$ENV_PATH" fetch --quiet origin

# 1. Re-attach worktrees for in-flight feature/* that lost theirs.
#    In-flight work always continues regardless of MAX_WORKTREES — the cap is on
#    NEW intake, not continuation. Order is FIFO by remote branch committerdate.
in_flight=()
for feature in $(git -C "$ENV_PATH" for-each-ref --sort=committerdate \
                   --format='%(refname:lstrip=4)' \
                   refs/remotes/origin/feature/ 2>/dev/null || true); do
  has_prd "$feature" || continue
  # Liveness gate: a MERGED/CLOSED PR means this feature is DONE. Its branch may
  # still linger on origin (we never force-delete it — a merged feature/* often
  # outlives its PR), but a done feature is NOT in-flight. Skipping it here is
  # load-bearing twice over: it stops step 3 from re-spawning a pointless
  # /address-feedback on a merged PR, AND it frees the MAX_WORKTREES slot the
  # phantom was holding so step 2 can claim a waiting PRD. Step 4 still tears down
  # the local worktree. Empty state — no PR opened yet (pre-PR pipeline phase) or a
  # transient gh failure — is fail-SAFE: treat as in-flight and keep advancing,
  # never silently abandon live work. Merged is terminal, so this never rewinds. (Inv 9)
  pr_state="$(ghe pr view "feature/${feature}" --json state --jq .state 2>/dev/null || echo "")"
  [[ "$pr_state" == "MERGED" || "$pr_state" == "CLOSED" ]] && continue
  wt="$(worktree_for "$feature")"
  if [[ ! -d "$wt" ]]; then
    git -C "$ENV_PATH" worktree add "$wt" "feature/${feature}" 2>/dev/null && bootstrap_worktree "$wt" || true
  fi
  [[ -d "$wt" ]] && in_flight+=("$feature")
done

# 2. Claim new PRDs up to remaining capacity (lazy claim). PRDs over cap stay in
#    prd/<slug>/* as the visible waiting queue. WATCH uses git refspec glob
#    syntax (* matches one path component). Per-dev default: prd/${SLUG}/*.
#    Shared pool: set WATCH_PATTERN=prd/*/*.
capacity=$(( MAX_WORKTREES - ${#in_flight[@]} ))
if (( capacity > 0 )); then
  for branch in $(git -C "$ENV_PATH" for-each-ref --sort=committerdate \
                    --format='%(refname:lstrip=3)' \
                    "refs/remotes/origin/${WATCH}" 2>/dev/null || true); do
    (( capacity > 0 )) || break
    feature="${branch##*/}"
    # Atomic rename = claim. Push failure (non-fast-forward) means another node
    # claimed first; skip silently. (Inv 2 + 7)
    if git -C "$ENV_PATH" push origin "origin/${branch}:refs/heads/feature/${feature}" \
                       ":refs/heads/${branch}" 2>/dev/null; then
      wt="$(worktree_for "$feature")"
      git -C "$ENV_PATH" worktree add "$wt" "feature/${feature}" 2>/dev/null && bootstrap_worktree "$wt" || true
      in_flight+=("$feature")
      capacity=$(( capacity - 1 ))
      TRANSITIONS=$(( TRANSITIONS + 1 ))
    fi
  done
fi

# 3. Advance each active feature by exactly ONE step. (Inv 5: one transition
#    per tick per branch.)
for feature in ${in_flight[@]+"${in_flight[@]}"}; do
  wt="$(worktree_for "$feature")"
  [[ -d "$wt" ]] || continue
  branch="feature/${feature}"

  # STUCK guard: a cap-hit handed this feature to the human via the PR.
  # Don't keep poking it — wait for merge/close (cleanup pass clears the
  # sentinel and the worktree).
  [[ -f "$STATE_DIR/stuck-${feature}" ]] && continue

  # HUMAN_REVIEW guard: the reviewer converged and the PR was handed
  # to the human for /evaluate-pr. Halt — no advance — until the human merges or
  # closes (cleanup clears the sentinels + worktree). The human drives from here:
  # evaluate, then merge, close, or fix locally and push. The loop never re-engages.
  # Post the session trail exactly once (guarded by the -posted marker).
  if [[ -f "$STATE_DIR/human-review-${feature}" ]]; then
    if [[ ! -f "$STATE_DIR/human-review-posted-${feature}" ]]; then
      signal_human_review "$feature"
      touch "$STATE_DIR/human-review-posted-${feature}"
    fi
    continue
  fi

  # Invariant 3 guard: worktree HEAD must match the branch we're advancing.
  # Skip otherwise (e.g., human manually checked out a different branch).
  current=$(git -C "$wt" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  [[ "$current" == "$branch" ]] || continue

  # Wipe: discard uncommitted state from any crashed skill. `-fd` (not `-fdx`)
  # preserves gitignored files like node_modules. (Inv 1 + 6)
  ( cd "$wt" \
    && git reset --hard HEAD --quiet \
    && git clean -fd --quiet \
    && git reset --hard "origin/$branch" --quiet )

  # Re-link the tier-1 skill symlinks after the wipe. They're untracked, and on
  # a branch whose .gitignore predates the managed block (e.g. a PRD filed
  # before env-init merged), `git clean -fd` just deleted them — and bootstrap
  # only runs at worktree creation. Idempotent and cheap; never let a skill run
  # skill-less.
  context-specs link "$wt" >/dev/null 2>&1 || true
  # A link failure must not kill the tick, but it must not be silent either: a
  # skill-less worktree reads as a model-quality problem, not a wiring one.
  [[ -e "$wt/.claude/skills/spec-planning/SKILL.md" ]] \
    || echo "warn: tier-1 skills missing in $wt after link — skills will run context-less" >&2

  # State machine: walk forward by exactly one step. Sentinel files gate each
  # transition. Every step has a bounded retry; at cap, signal_stuck posts to the
  # PR (opening one as a draft if necessary) with the step, the session log, an
  # optional failing-output tail, and a pointer to /improve-context. The stuck
  # sentinel above halts further advance until the human merges or closes.
  if   [[ ! -f "${wt}/specs/${feature}/.planning-done" ]]; then
       attempts_file="$STATE_DIR/planning-attempts-${feature}"
       attempts=$(cat "${attempts_file}" 2>/dev/null || echo 0)
       if (( attempts >= PLANNING_CAP )); then
         echo "STUCK: ${feature} at /spec-planning (${PLANNING_CAP}x)." >&2
         signal_stuck "$feature" "spec-planning" "$PLANNING_CAP"
       else
         echo $((attempts + 1)) > "${attempts_file}"
         run_claude spec-planning "$feature" $((attempts + 1)) "$wt" "/spec-planning ${feature}"
       fi

  elif [[ ! -f "${wt}/specs/${feature}/.validated" ]]; then
       attempts_file="$STATE_DIR/validate-attempts-${feature}"
       attempts=$(cat "${attempts_file}" 2>/dev/null || echo 0)
       if (( attempts >= VALIDATE_CAP )); then
         echo "STUCK: ${feature} at /spec-validate (${VALIDATE_CAP}x)." >&2
         signal_stuck "$feature" "spec-validate" "$VALIDATE_CAP"
       else
         echo $((attempts + 1)) > "${attempts_file}"
         run_claude spec-validate "$feature" $((attempts + 1)) "$wt" "/spec-validate ${feature}"
       fi

  elif [[ ! -f "${wt}/specs/${feature}/.prd-passed" ]]; then
       # Run the PRD runner only until it first goes green, then cache the result.
       # The runner may be an LLM-as-judge (cost + non-determinism), so re-running
       # it every tick would burn tokens and could flip 0->1 and wrongly re-kick
       # implement on an already-PR'd feature. Forward-only (Inv 9): once green, the
       # PRD gate stays satisfied; local-checks (re-run every tick), CI, the
       # PRD-aware reviewer, and the human merge cover any later regression. The
       # gate still ran and passed before merge, so this is not an Inv 8 bypass.
       if ( cd "${wt}" && "./prds/${feature}/run-prd-test.sh" ); then
         # First green — record a committed+pushed sentinel so it survives the
         # tick-start wipe and is never re-run. The dispatcher (not the skill)
         # writes it because only the dispatcher's gate observed green. `|| true`:
         # a push failure self-heals (next wipe drops the un-pushed commit -> the
         # sentinel is absent -> re-run) and must not abort the tick.
         ( cd "${wt}" \
           && touch "specs/${feature}/.prd-passed" \
           && git add "specs/${feature}/.prd-passed" \
           && git commit -m "harness: PRD runner green for ${feature}" --quiet \
           && git push --quiet ) && TRANSITIONS=$(( TRANSITIONS + 1 )) || true
       else
         # Bounded retry: if the PRD runner keeps failing, the *plan* may be broken,
         # not just the code, and re-invoking implement forever burns compute. (Inv 8)
         attempts_file="$STATE_DIR/implement-attempts-${feature}"
         attempts=$(cat "${attempts_file}" 2>/dev/null || echo 0)
         if (( attempts >= IMPLEMENT_CAP )); then
           # Capture the latest failing output for the human's diagnosis dossier.
           ( cd "${wt}" && ./prds/${feature}/run-prd-test.sh ) > "$STATE_DIR/stuck-output-${feature}.log" 2>&1 || true
           echo "STUCK: ${feature} at /implement-mainspec — PRD runner ${IMPLEMENT_CAP}x." >&2
           signal_stuck "$feature" "implement-mainspec" "$IMPLEMENT_CAP" "$STATE_DIR/stuck-output-${feature}.log"
         else
           echo $((attempts + 1)) > "${attempts_file}"
           run_claude implement-mainspec "$feature" $((attempts + 1)) "$wt" "/implement-mainspec ${feature}"
         fi
       fi

  elif [[ -x "${wt}/scripts/local-checks.sh" ]] \
       && ! ( cd "${wt}" && ./scripts/local-checks.sh ); then
       # Optional gate. Auto-fix first (attempt 0), focused LLM fix (attempt 1),
       # then STUCK at LOCAL_CHECKS_CAP. (Inv 8)
       attempts_file="$STATE_DIR/local-check-attempts-${feature}"
       attempts=$(cat "${attempts_file}" 2>/dev/null || echo 0)
       if (( attempts >= LOCAL_CHECKS_CAP )); then
         ( cd "${wt}" && ./scripts/local-checks.sh ) > "$STATE_DIR/stuck-output-${feature}.log" 2>&1 || true
         echo "STUCK: ${feature} at local-checks (${LOCAL_CHECKS_CAP}x)." >&2
         signal_stuck "$feature" "local-checks" "$LOCAL_CHECKS_CAP" "$STATE_DIR/stuck-output-${feature}.log"
       elif (( attempts == 0 )); then
         ( cd "${wt}" && ./scripts/local-checks.sh fix || true )
         if ! ( cd "${wt}" && git diff --quiet ); then
           ( cd "${wt}" \
             && git commit -am "chore: auto-fix lint/format" --quiet \
             && git push --quiet )
           TRANSITIONS=$(( TRANSITIONS + 1 ))
         fi
         echo 1 > "${attempts_file}"
       else
         run_claude fix-local-checks "$feature" $((attempts + 1)) "$wt" "/fix-local-checks ${feature}"
         echo $((attempts + 1)) > "${attempts_file}"
       fi

  elif ! ghe pr view "${branch}" >/dev/null 2>&1; then
       ghe pr create --base main --head "${branch}" --fill
       TRANSITIONS=$(( TRANSITIONS + 1 ))
       rm -f "$STATE_DIR/planning-attempts-${feature}"
       rm -f "$STATE_DIR/validate-attempts-${feature}"
       rm -f "$STATE_DIR/local-check-attempts-${feature}"
       rm -f "$STATE_DIR/implement-attempts-${feature}"
       # No reviewer configured (empty marker) → nothing to converge on; hand
       # straight to the human for /evaluate-pr. Guard halts next tick.
       [[ -z "$REVIEW_CLEAN_MARKER" ]] && touch "$STATE_DIR/human-review-${feature}"

  # CONVERGED — the reviewer posted the clean marker. Hand the PR to the human
  # for /evaluate-pr. The guard above halts the feature next tick.
  # Checked BEFORE the findings loop so a clean PR never marches to a false STUCK
  # on a sticky historical COMMENTED review.
  elif reviewer_converged "${branch}"; then
       touch "$STATE_DIR/human-review-${feature}"

  # Reviewer has findings and hasn't signalled done. Address them if budget
  # remains; at FEEDBACK_CAP rounds without convergence, STUCK (covers genuine
  # non-convergence AND a reviewer that flubbed the marker — human takes over).
  elif ghe pr view "${branch}" --json reviews \
         --jq '.reviews[] | select(.state=="CHANGES_REQUESTED" or .state=="COMMENTED")' \
         2>/dev/null | grep -q .; then
       rounds_file="$STATE_DIR/feedback-rounds-${feature}"
       rounds=$(cat "${rounds_file}" 2>/dev/null || echo 0)
       if (( rounds >= FEEDBACK_CAP )); then
         echo "STUCK: ${feature} at PR review (${FEEDBACK_CAP} rounds)." >&2
         # No tee'd output — the failure signal is the unresolved PR comments.
         signal_stuck "$feature" "address-feedback" "$FEEDBACK_CAP"
       else
         echo $((rounds + 1)) > "${rounds_file}"
         run_claude address-feedback "$feature" $((rounds + 1)) "$wt" "/address-feedback ${feature}"
       fi
  fi
done

# 4. Cleanup pass: tear down per-feature worktree + counter files for
#    closed/merged PRs. Each finished feature is torn down independently.
for feature in $(git -C "$ENV_PATH" for-each-ref --format='%(refname:lstrip=4)' \
                   refs/remotes/origin/feature/ 2>/dev/null || true); do
  state=$(ghe pr view "feature/${feature}" --json state --jq .state 2>/dev/null || echo "")
  if [[ "${state}" == "MERGED" || "${state}" == "CLOSED" ]]; then
    git -C "$ENV_PATH" worktree remove "$(worktree_for "$feature")" --force 2>/dev/null || true
    # The worktree add created a local feature/<f> branch in the developer's
    # clone; drop it so a reused feature name can't collide with a stale branch.
    git -C "$ENV_PATH" branch -D "feature/${feature}" 2>/dev/null || true
    rm -f "$STATE_DIR/feedback-rounds-${feature}"
    rm -f "$STATE_DIR/local-check-attempts-${feature}"
    rm -f "$STATE_DIR/implement-attempts-${feature}"
    rm -f "$STATE_DIR/planning-attempts-${feature}"
    rm -f "$STATE_DIR/validate-attempts-${feature}"
    rm -f "$STATE_DIR/stuck-${feature}"
    rm -f "$STATE_DIR/stuck-output-${feature}.log"
    rm -f "$STATE_DIR/stuck-body-${feature}.md"
    rm -f "$STATE_DIR/human-review-${feature}"
    rm -f "$STATE_DIR/human-review-posted-${feature}"
    rm -f "$STATE_DIR/human-review-body-${feature}.md"
    rm -f "$STATE_DIR/sessions-${feature}.tsv"
  fi
done

# Post-merge memory update is NOT here. /learn runs in its own loop
# (scripts/learn-dispatch.sh, driven by the CLI supervisor on its own interval),
# in its own dedicated worktree, so a multi-minute memory rebuild never blocks —
# and is never blocked by — this feature/build loop. The two loops coordinate only
# through git (the refs/harness/last-learned watermark + ls-remote idempotency on
# learn/<sha>). See references/dispatcher-explained.md ("The memory loop").

# STUCK escalation is handled inline in step 3 by signal_stuck (which opens or
# comments on the PR with the session log + a pointer to /improve-context — the
# front door for resolution). The human takes over from there — diagnoses the
# context defect first, corrects it on the branch, fixes the code, then merges.
# /learn picks up the context correction at merge.

# Exit contract for the supervisor: 10 = advanced (re-invoke immediately to
# drain), 0 = idle (sleep the full interval). STUCK-only ticks made no
# transition, so they exit 0 — a stuck environment never hot-loops.
if (( TRANSITIONS > 0 )); then
  exit 10
fi
exit 0
