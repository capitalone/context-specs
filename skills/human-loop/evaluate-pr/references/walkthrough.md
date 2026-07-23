# Walkthrough: transferring understanding

This is the discipline behind Step 4–5. The goal is not to *describe* the diff — the
human can read a diff. The goal is to leave the human able to reason about the change
without you: to predict its behavior in unfamiliar cases, defend its design, and spot
where the next feature will rub against it.

> Governing principle: **outsource thinking, not understanding.** Transfer the
> unverifiable; skip the verifiable. If a fact is checkable by a tool (syntax, an API
> signature, whether a test passes), don't spend the human's attention on it.

## The four lenses

Walk the change through these, in roughly this order. Each is a *why*, not a *what*.

1. **Scenarios — what the system now does.** Start from the PRD's definition-of-done
   scenarios (they're literally the checks in `run-prd-test.sh`). For each: what's the
   user-visible behavior, and why is *that* the right behavior? Run it live where you can
   (see `verdict.md` for running). Seeing it beats reading it.

2. **Edge cases — where it bends.** The interesting understanding lives at the
   boundaries: empty input, missing auth, concurrent access, the second-largest case,
   the malformed payload. For each that matters: what does the code do, and *why was it
   handled this way* rather than another? If an edge case isn't handled, decide together
   whether that's a deliberate scope cut (fine — is it in the PRD's "out of scope"?) or a
   gap (a change request, possibly a PRD defect).

3. **Design decisions — the forks not taken.** Surface the choices the implementation
   made that *could have gone differently*: this data shape vs. that one, sync vs. async,
   where the logic lives. For each, articulate the trade-off. This is where taste enters:
   "could this have been simpler?" is a design-decision question.

4. **Core abstractions — the load-bearing shapes.** What new abstraction (function,
   module, type, boundary) does this introduce, and is it sound? Judge it against the
   Expert's patterns: does it fit how this codebase already factors things, or does it
   cut across them? An unsound abstraction is the most expensive thing to merge, because
   every future change inherits it.

## Socratic prompts (use, don't recite)

Pull these out to make the human *do* the reasoning rather than receive it:

- "Before we look — what do you think happens when <edge case>?"
- "Why this shape and not <alternative>? What would we gain or lose?"
- "Is this the abstraction the next three features will want, or the one they'll fight?"
- "Where would you look first if this broke in production?"
- "Does this *feel* right? If the UX seems dull or the flow seems awkward, name it."

## What to skip

- Formatting, naming nits, lint-level concerns — the bot owns these.
- Line-by-line narration of mechanical code.
- Re-deriving anything already settled in the bot's review (you summarized it in Step 2).

## Surfacing changes

As you walk, you'll find things. Sort each into:

- **Taste / could-be-better** — real but not blocking. The human decides whether it's
  worth a fix or a "good enough, I understand the trade-off now."
- **Implementation gap** — the code doesn't satisfy the PRD. Fix it.
- **PRD defect** — the intent itself missed something obvious-in-hindsight. The most
  valuable find: Evaluate just improved the *next* Intent. Here, fix the **code** for
  this PR.

When something should change, **you fix it here and push** — there is no handing work
back to the loop. Make the edit with the human in the detached checkout, commit, and
`git push origin HEAD:feature/<f>` (see `verdict.md`). Keep fixes scoped to what was
discussed; this is the last mile, not a re-implementation.

Separately, the walk may surface not a change to *make* but a pattern to *remember* — a
convention this PR establishes, an invariant it upholds, an abstraction worth naming for
the next feature (the **core-abstractions** lens is where these usually appear). If the
**human** judges it worth keeping, capture it in the Expert (or AGENTS.md, if it clears
that higher bar) and commit it on the branch with the code. It rides into `main` with the
merge, where `/learn` honors human-authored memory edits as authoritative — its P7
*extends* them rather than re-litigating them. This is the one thing `/evaluate-pr` writes
to memory, and only when the human, not you, recognizes the pattern. The PRD is never
touched here — fix code and seed memory, but leave the spec of record alone.
