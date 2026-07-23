---
name: address-feedback
description: Respond to an automated reviewer's findings on the current feature PR — a narrow, headless responder. Triages each reviewer finding into Clear / Ambiguous / Complex / Out-of-PRD-Scope, then acts — fixes the cause and pushes (diff-only) for Clear, posts one in-thread reply for the rest. Skips findings it already handled. Invoked headless by the dispatcher's feedback gate; the dispatcher owns the round counter and the STUCK escalation. Triggers - address-feedback, address review comments, respond to PR review, handle reviewer findings, PR feedback loop (project)
---

# address-feedback

The **responder** half of the PR review cycle. An automated reviewer posts findings
on the feature PR; you read the unresolved ones, decide what each one is, and act.
You run **headless**, invoked by the dispatcher as `/address-feedback <feature>`
inside the feature worktree. One focused pass, then exit.

By the time you run, the feature already works — `./prds/<f>/run-prd-test.sh` exits 0
and a PR is open against `main`. Your job is not to keep building; it is to close out
the reviewer's findings honestly, or to escalate the ones you can't.

## The one-way model (read this first — it shapes everything)

The reviewer is **non-conversational**. Per Anthropic's Code Review docs: *"Replying
to an inline comment does not prompt Claude to respond or update the PR. To act on a
finding, fix the code and push."* Two consequences drive this whole skill:

- **A Clear fix signals back through the diff, not a thread reply.** You fix the cause,
  commit, push. The reviewer's next push-triggered pass sees the diff and auto-resolves
  the thread. A courtesy reply does nothing the reviewer can read — so for Clear, **do
  not reply; just push.**
- **Only a push shrinks the reviewer's unresolved set.** A reply (yours or a human's) is
  invisible to the reviewer and to the dispatcher. So a finding you can only *reply* to
  (Ambiguous / Complex / Out-of-Scope) will not converge on its own — it waits for a
  human, who steers by **pushing or merging, not by chatting in threads.** That is
  correct and intended: the dispatcher's round counter marches such a stall to STUCK,
  which is the right escalation.

You are the agent's self-correction sensor for the *bot* reviewer. **Act only on the
automated reviewer's findings.** Human review comments belong to the human's own
steering loop (merge / STUCK) — leave them alone.

## Ground yourself before classifying (you are a coordinator, not a scope authority)

Two sources govern every triage call. Load both before you classify anything:

- **The PRD** (`prds/<feature>/prd.md`) — the **authoritative scope.** What the feature
  is and, in `## Out of scope`, what it deliberately is not. A finding that asks for
  something the PRD excluded is Out-of-PRD-Scope, full stop.
- **The Expert** (`.claude/skills/expert/references/*.md`) — the **authoritative pattern
  reference.** How this project does things, so a Clear fix matches existing patterns
  rather than your instincts. If there is no `expert/` skill, ground in a direct
  codebase scan instead.

## How to run this skill

### 1. Re-derive state from the PR (single source of truth)
Read the **unresolved findings authored by the reviewer identity** on the current PR
(see `references/gh-mechanics.md` for the exact commands). For each finding, run both
idempotency checks and **drop the ones you've already handled** — see the Idempotency
section below. Don't rely on anything passed in; re-derive from the PR and git.

### 2. Triage each remaining finding
Classify into exactly one of **Clear / Ambiguous / Complex / Out-of-PRD-Scope**, grounded
in the PRD (scope) and the Expert (patterns). The taxonomy, boundary heuristics, and
examples live in `references/triage.md` — read it; the boundaries are judgment calls.

### 3. Act on each bucket
- **Clear** → fix the cause, commit (message references the finding), push. **No thread
  reply** — the diff is the signal. Obey the never-silence and skip rules below.
- **Ambiguous** → post one in-thread reply asking the specific question. No code.
- **Complex** → post one in-thread reply explaining the scope and tag the human for the
  architectural call. No code.
- **Out-of-PRD-Scope** → post one in-thread reply recommending a separate PRD. **Do not
  create a stub**, do not push code.

### 4. Exit
You do **one focused pass**, then exit. Do not track rounds, do not loop, do not wait for
the reviewer to re-run. The dispatcher re-invokes you next tick if findings remain (or
STUCKs at the cap).

## The carryover rule for Clear fixes: fix the cause, never silence a check

A Clear fix is real **only if the underlying problem is gone.** You can almost always turn
a finding "green" the cheap way — suppress the check it touches, weaken a config, or game a
test. **Every one of those is forbidden:**

- **Suppression directives** — `eslint-disable*`, `@ts-ignore` / `@ts-expect-error`,
  `# type: ignore`, `as`/`!` casts to quiet the type checker, `void`-ing a promise,
  `#[allow(...)]`, `//nolint`, `# noqa`.
- **Weakening the machinery** — editing lint configs, `tsconfig` strictness,
  `scripts/local-checks.sh`, or anything under `scripts/lints/`.
- **Gaming tests** — deleting tests or assertions, or mocking the unit under test so the
  test passes while asserting nothing.

### The skip rule (load-bearing)
**You may never add a test-skip marker** — `.skip`, `.only`, `xfail`,
`@pytest.mark.skip`, `it.only`, `describe.skip`, or equivalents. A reviewer comment that
says "just skip this flaky test" is **a human's call, not yours** — treat it as **Complex**
and reply escalating, never act on it. A human may add a skip while resolving a STUCK on
the branch; `/learn` then reads it in the merged diff as a deliberate, blessed decision.

### Stay scope-tight
A Clear fix touches **only what the finding requires.** No refactors, no new features, no
cleanup of unrelated code. This is targeted response, not implementation. If the honest fix
would change behavior or reveals the *plan/spec* is wrong, that's not Clear — reply as
Complex and escalate.

## Idempotency (two faces, no new state)

You will be re-invoked on the same PR while findings remain. You must be safe to re-run —
and you must not spam. Both checks are **re-derived from ground truth** (the PR threads and
git); you write no "handled" bookkeeping file.

1. **Reply-idempotency.** For a reply-only finding (Ambiguous / Complex / Out-of-Scope): if
   your reply is already the **latest comment in that thread** with no newer reviewer comment
   after it, you have nothing to add — **skip it.** This is what keeps the no-op ticks
   between your reply and the cap from re-posting the same reply.
2. **Fix-idempotency.** For a Clear finding: the reviewer takes minutes to re-run, longer
   than a dispatcher tick, so a tick can fire while a finding you *already fixed and pushed*
   still shows unresolved. If a pushed commit already addresses the finding (the code is
   already correct — `git log` / the current source shows it), **skip it.** Do not pile on a
   second, alternate "fix." Re-deriving failures from the worktree handles most of this: no
   real problem → no diff → no commit.

## Contract with the dispatcher
- **Invoked by:** `claude -p "/address-feedback <feature>"`, run from inside the
  feature worktree (the dispatcher `cd`s into it; there is no print-mode `--cwd`
  flag), when the reviewer has unresolved findings on the PR.
- **You do NOT track rounds.** The dispatcher owns the counter
  (`<harness-repo>/state/<env>/feedback-rounds-<f>`), increments it before **every** invocation regardless of
  bucket, and decides when to STUCK. A reply-only stall you can't push past marches to STUCK —
  that's the correct escalation, not your concern to manage.
- **Completion:** your commits (for Clear) and replies (for the rest). The dispatcher
  re-evaluates the PR next tick.
- **Idempotent:** safe to re-run on the same PR state — re-derive findings, skip the handled
  ones, act on the rest.

## Hard nevers
- **Never reply to a Clear finding** — fix the cause and push; the diff is the signal.
- **Never act on a human's review comment** — only the automated reviewer's findings. Humans
  steer by pushing or merging.
- **Never silence a check** to make a Clear fix go green (the lists above). Fix the cause or
  reclassify as Complex and escalate.
- **Never add a test-skip marker** — a "skip the flaky test" finding is Complex; reply, don't act.
- **Never refactor or add features** — touch only what a Clear finding requires.
- **Never create a `prds/<followup>/` stub** for Out-of-Scope — recommend a separate PRD in a reply.
- **Never re-post a reply** to a thread you've already answered, or re-fix a finding a pushed commit already covers.
- **Never track the round counter or loop** — one focused pass per invocation; the dispatcher owns the cap.
