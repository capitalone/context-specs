# Reviewer options

The PR review cycle is OPTIONAL but real. When set up, an automated reviewer
flags issues on the feature PR and `/address-feedback` responds, with a
deterministic round cap so the loop can't run away. Without it, every comment
lands on a human and the harness just opens PRs and waits for merge.

Present the three paths below, explain the tradeoffs, and let the user choose.
If they choose a reviewer, you create the artifacts for that path. If they
decline, the harness still works — it just has no automated review step.

## The three paths

### A. Self-hosted via `claude-code-action` (recommended default)

A GitHub Actions workflow that auto-reviews on PR open and on every push.
Non-conversational and **PR-triggered only** — it is the harness's one-way
reviewer (see "Interactive `@claude` agent" below for the separate, optional
conversational mode).

- **Setup:** drop `assets/workflows/claude-review.yml` into `.github/workflows/`,
  drop `REVIEW.md` at repo root, add the auth secret (next bullet), and **pin**
  the action: replace `@v1` with the current release tag (env-init looks up
  and pins the latest at setup time).
- **Auth — two options, pick one:**
  - **`CLAUDE_CODE_OAUTH_TOKEN`** — uses a Claude **Max/Pro subscription**
    (generate with `claude setup-token`, then add as a repo secret). No metered
    bill, but CI reviews share the subscription's usage limits with interactive use.
  - **`ANTHROPIC_API_KEY`** — metered pay-as-you-go API billing (console.anthropic.com).
    Isolated from any subscription; the right default for teams / CI / the
    server-harness upgrade path. The Max plan and the API are **separate billing
    products** — an API key does not draw from a subscription.
- **Written for `claude-code-action` v1:** drives the review via `prompt`
  (pointing at REVIEW.md) + `track_progress: true` + `claude_args`, with
  `permissions: id-token: write`. (The pre-v1 `mode: review` /
  `review_instructions_path` inputs are gone — v1 silently ignores them.)
- **v1 same-content rule:** the workflow file must be **byte-identical on the PR
  branch and the default branch** (a PR can't alter its own reviewer). So edits
  to `claude-review.yml` only take effect once merged to `main`; you can't test a
  change to it from a feature branch.
- **Cost:** often well under $1/PR with a small model for the first pass +
  Expert as context-narrowing + prompt caching on stable parts.
- **Requires:** a GitHub remote; ability to set a repo secret.
- **Best for:** most projects.

### B. Anthropic managed Code Review

Install the GitHub App, configure Review Behavior per-repo.

- **Setup:** install the app + configure in GitHub; drop `REVIEW.md` (the
  managed service consumes the same file).
- **Cost:** ~$15-25/PR; multi-agent parallel review with a verification step.
- **Best for:** teams that want it turnkey and have the budget.
- **Note:** at this cost, the round cap (default 5) can mean ~$125 worst case —
  mention the cost-cap follow-up (design Open Gap) if the user picks this.

### C. None (v1 build/test/PR loop only)

No reviewer, no `REVIEW.md`. The harness implements, passes the PRD runner,
opens a PR, and stops for a human. Perfectly valid starting point; the reviewer
can be added later with one workflow file and no other changes.

## What's shared across A and B

- **`REVIEW.md`** (canonical, `assets/REVIEW.md`) — the convergence rules. Both
  self-hosted and managed read it. Key rule: after the first review, suppress
  new nits and post Important findings only. This is the primary convergence
  mechanism; the round counter is just the safety net.
- **The responder** — `/address-feedback` triages each comment into Clear /
  Ambiguous / Complex / Out-of-PRD-Scope. The dispatcher increments the round
  counter before *every* invocation regardless of bucket, so a reply-only stall
  marches to STUCK — the correct escalation, since only a push converges a PR.
  The dispatcher enforces the cap, not the agent.
- **The reviewer is non-conversational.** It posts findings; the implementer
  signals back via commits, not comment replies. Comment threads are
  human↔human.

## Interactive `@claude` agent (separate, optional — not bundled)

Keeping the self-hosted reviewer PR-triggered does **not** lock users out of
`@claude`-style on-demand help. The interactive agent (Claude responds to a
human's `@claude …` comment and **can edit code + push** — `contents: write`,
conversational) is a *different mode* of the same action and ships as Anthropic's
stock `examples/claude.yml`. It's a separate `.github/workflows/` file on
different triggers (`issue_comment`, etc.); the two coexist with no oscillation.

We deliberately do **not** bundle it, so the harness's automated reviewer stays
one-way. If a user wants the interactive assistant too, point them at
the stock `claude.yml` as a one-file add — orthogonal to the harness. (Managed
Code Review, option B, includes `@claude` mentions natively.)

## Migration note

A and B share the same `REVIEW.md` and the same automated trigger surface (PR
open + push). Switching between them is one workflow-file change, nothing else.
So starting at C and moving to A later is cheap — reassure the user that
declining now isn't a one-way door. (`@claude` on-demand mentions are native to
B and a separate add-on for A, per above.)

## Heterogeneous reviewers (upgrade path, not a v1 option)

Some teams run CodeRabbit (style/conventions lane) + Claude (logic lane) in
parallel. They don't oscillate because they flag different classes of issue.
Worth mentioning only if the user already pays for CodeRabbit and asks. Do NOT
run two Claude reviewers in the same lane — that oscillates.

## What you generate per choice

| Choice | Files created |
|--------|---------------|
| A | `.github/workflows/claude-review.yml` (pinned to the current release) + `REVIEW.md` + the chosen auth secret (`CLAUDE_CODE_OAUTH_TOKEN` *or* `ANTHROPIC_API_KEY`) |
| B | `REVIEW.md` + instructions to install the GitHub App |
| C | nothing |
