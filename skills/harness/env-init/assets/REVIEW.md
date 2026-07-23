# Review instructions

## Re-review convergence
After the first review, suppress new Nits and post Important findings only.
Do not re-flag findings already addressed in a subsequent push.

## Signal when you are done (REQUIRED — the harness depends on this)
When you review a revision and have **no Important (🔴) findings to request** on
it, post a **top-level PR comment whose body is exactly**:

    HARNESS_REVIEW_CLEAN

Post it only when you would otherwise be approving — i.e., all your follow-ups are
answered and nothing Important remains on the current commit. Post it once per
clean revision (a later push that you then find issues with supersedes it — just
post your findings as normal; post the marker again only when clean again).

This is how the harness knows the review loop has converged and hands the PR to a
human for evaluation. If you forget it, the loop eventually reaches its round cap
and escalates to a human anyway, but the marker is the clean path — don't skip it.

## What Important means here
Reserve 🔴 Important for findings that would break behavior, leak data, or
introduce a regression against the PRD's definition of done. Style and
naming are 🟡 Nit at most.

## PRD-aware
The PRD lives at `prds/<feature>/prd.md`; the runnable definition of done is
`prds/<feature>/run-prd-test.sh`. If a finding is outside the PRD's stated
scope, mark it 🟣 Pre-existing — the responder will reply with a follow-up
PRD recommendation rather than implement it.

## Cap the nits
Report at most three Nits per review. If you found more, summarize as
"plus N similar items" rather than posting them all.

## Don't re-flag what the deterministic gate owns
`scripts/local-checks.sh` (lint, format, typecheck, fast tests, custom lints) runs
before this review. Don't spend findings on lint/format/type issues or anything
those checks own — they're the computational floor; your job is the semantic/logic
review they can't do. **But** if a check was reached green by *silencing* — a new
suppression directive (`@ts-ignore`, `eslint-disable`, `as`/`!`, …), a weakened
config, or a skipped/deleted test — flag it 🔴 Important. A green gate reached by
silencing is a regression in disguise.

## Non-conversational
Replying to an inline comment does not prompt you to respond or update the PR.
The implementer acts on findings by pushing commits, not by replying. Comment
threads are for human-to-human discussion.
