# STUCK forensics: from PR to evidence, and where fixes land

This is the discipline behind route (a). The goal is not to *summarize* every session —
that's a transcript dump, and it tells you nothing. The goal is to read the few sessions
that fought, with the four lenses, until you can name which piece of context shaped each
decision the human cares about — then land the fix where it survives.

> Governing principle: **the sessions are evidence, not the verdict.** You are reading
> agents reading context. The finding is always about the *context*, never the agent.

## Where session IDs come from (the PR comment, full stop)

The harness posts the session table on the PR **deterministically, from the dispatcher**
(no LLM in that path): `render_sessions_table` feeds `signal_human_review`,
`signal_stuck`, and `signal_learn_review`, each ending in `gh pr comment`. That comment
is the durable artifact. Read it:

```bash
gh pr view <pr> --json comments --jq '.comments[].body'
```

The table is `| Time | Step | Attempt | Session ID | Exit |`, with the step and session ID
backtick-wrapped. `scripts/resolve-sessions.sh <PR#|feature>` parses exactly this and emits
`<session_id>\t<jsonl_path|MISSING>` per row.

**Do not read the harness repo's `state/<env>/sessions-<f>.tsv`.** It carries an extra `duration_s` column and
untruncated rows, but the cleanup pass `rm -f`s it on every merged/closed PR — so for a
merged PR (the `/learn`-audit case) it's already gone. The PR comment is the contract; the
TSV is ephemeral working state. (One consequence: `render_sessions_table` does `tail -n 20`
and drops `duration_s`, so from the PR you triage on `Step` / `Attempt` / `Exit`, and a
trail longer than 20 sessions is truncated — note it to the human if you hit the cap.)

## Locating the trace content

Session **content** lives in local JSONL, one event per line (user message, tool call,
assistant response — system prompts are not in the transcript):

```
~/.claude/projects/<encoded-project>/<session-id>.jsonl
```

`<encoded-project>` is Claude Code's slugified working-directory path. Don't try to
reconstruct it — **glob** instead, which the resolver already does:

```bash
ls ~/.claude/projects/*/<session-id>.jsonl
```

Read a trace with `jq` rather than eyeballing raw JSON — e.g. the assistant/user turns:

```bash
jq -rc 'select(.type=="user" or .type=="assistant") | {type, ts:.timestamp}' <path>
```

…then open the specific tool calls and turns that matter. You don't need every line; you
need the moments where the agent loaded context, or should have.

## The triage map: where to START, not who to blame

A trail can be dozens of sessions. The table tells you which fought — and that's your
**entry point for reading**, not your conclusion about fault:

- **High `Attempt`** — the dispatcher retried this step. Something went wrong repeatedly;
  the *why* is the prize.
- **Non-zero `Exit`** — the skill errored or hit a cap. Always worth opening.
- **A step that recurs** (e.g. `implement-mainspec` three times) — a struggle cluster.

Open those first. But **the symptom is rarely the cause.** A step fails because of what it was
*handed*, and what it was handed came from the step before it. So once you're in the failing
session, work **backward**:

1. Read what the failing agent was given — the spec slice, the PRD section, the Expert it
   loaded (or didn't).
2. If the flaw was already present in that input, open the step that *produced* it and read
   *its* trace. (A bad spec from `spec-planning` shows up as repeated failures in
   `implement-mainspec` — the blame is upstream of the symptom.)
3. Keep walking back until you reach the **earliest** point where the context first led an
   agent wrong. That's the root; that's what an eval should freeze and a context fix should
   repair.

There are **no mechanical rules** ("failed N times at step X → step X is to blame"). The table
position is a starting line. Let the evidence decide. Tell the human where you're starting and
why in two lines before diving, and update them as the trail leads you upstream.

## The four reading lenses

For each session you open, ask in roughly this order. Each is about the *context*, not the
code.

1. **Context-load — did it open the right context?** Did the session read the Expert
   (`.claude/skills/expert/references/*.md`), the root/nested AGENTS.md, the PRD, the spec?
   An agent that never opened the Expert before a non-trivial decision is the single most
   common defect — and it's often an AGENTS.md *pointer* problem, not the agent's fault.
2. **Context-fidelity — did it follow what it read?** It loaded the convention and then did
   something else. That points at context that's *present but unconvincing* — buried,
   ambiguous, or contradicted elsewhere.
3. **Retry-cause — why did `Attempt` climb?** Re-deriving the same setup each attempt
   (missing procedural memory), fighting a check it didn't understand (a lint whose message
   isn't a fix-prompt), or chasing a moving target (under-specified spec)?
4. **Decision-provenance — grounded or guessed?** When the agent made a load-bearing choice,
   trace it back: did it cite the PRD/spec/Expert, or invent it? A guessed decision that
   happened to be right is still a context gap — next time it guesses wrong.

## Classify, don't accumulate

Every finding sorts into exactly one of two buckets — and the second is as valuable as the
first:

- **Context defect** — fixable: a missing Expert convention, a stale/missing AGENTS.md
  pointer, a skill whose own text steered wrong, an under-specified spec section. These
  become evals and/or context fixes.
- **Inherent difficulty** — the task was just hard; no context change would have helped.
  Name it and move on. Calling difficulty a "defect" over-fits memory with noise.

## Where the routed fix is written

Route each context defect to exactly one destination — the same routing discipline the
project's memory uses:

- **A lint** — when the rule is *mechanically checkable*. Add it under `scripts/lints/`,
  wire into `scripts/local-checks.sh`; it must pass against current code before it's
  included. The lint *is* the regression test — don't also write an eval for it.
- **Eager prose (AGENTS.md)** — only when it clears all five predicates (see
  `context-levers.md`); root or the nested file the rule is local to.
- **Lazy prose (an Expert reference file)** — the default home. Pick the file by prefix
  (`how-to-*`, `concept-*`, `pattern-*`, `invariant-*`, `example-*`); if none fits, write
  a clear, correctly-scoped new shard.
- **A skill defect** — if a *skill's own text* steered the agent wrong, the fix is that
  skill's `SKILL.md` (or its `references/`). Edit it like any other context, on the branch.
- **Nowhere** — inferable from the code, taste-only, or transient. Prefer nothing over
  noise.

## Where the changes land: always a branch

Changes ride a branch so they stay **reviewable and revertible** — every context edit
reaches `main` through a PR a human merges, and the post-merge `/learn` pass extends
human-authored memory edits rather than second-guessing them.

### Path A — add to the PR being resolved (default)

Use when the PR is going to **merge** (a STUCK you're resolving, or a converged PR you'll
keep). The harness's per-feature worktree still holds the branch, and git refuses the same
branch in two worktrees — so commit from a **detached checkout** of the PR head:

```bash
git fetch origin
git checkout --detach origin/<branch>          # feature/<f> or learn/<sha>

# ... fix the context (Expert / AGENTS.md / skill / lint), then the code, with the human ...
# ... any new eval: RED before the context fix, GREEN after (right-reason) ...

git add -A
git commit -m "context+fix: <what the trail revealed, in one line>"
git push origin HEAD:<branch>                  # detached HEAD -> push to the branch ref
```

The reviewer re-runs on the push; the human merges when ready.

### Path B — fresh capture branch (the discard case)

Use when the human will **close** the PR but still wants the learnings. `/learn` never runs
without a merge to `main`, so a learning attached only to a doomed PR dies with it. Land it
on its own branch instead, off clean `main`, carrying **only** the eval/context changes:

```bash
git fetch origin
git checkout --detach origin/main
git switch -c capture/<slug>                   # <slug>: short, describes the learning

# ... author the eval and/or context edits, with the human ...

git add -A
git commit -m "capture: <learning from the discarded PR, in one line>"
git push -u origin capture/<slug>
gh pr create --base main --head capture/<slug> \
  --title "capture: <learning>" \
  --body "Learnings salvaged from #<original-pr> (being closed): <two lines>."
```

Then the human can close the original PR freely:

```bash
gh pr close <original-pr> --comment "Closing; learnings captured in #<capture-pr>."
```

### Choosing the path

It's the human's explicit call, framed by the PR's fate:

| The PR will… | Path | Why |
|---|---|---|
| **Merge** | **A** — add to the PR | Changes ride in with the work; one merge, one `/learn` pass. |
| **Be discarded** | **B** — capture branch | The learning outlives the closed PR. |

When unsure, ask: *"are we keeping this PR?"* The answer picks the path. End where the
user started — never leave them on a detached HEAD or a capture branch.

## CI / remote degradation

If `resolve-sessions.sh` reports `MISSING` for a trace, the harness ran on another machine
(CI/server) and the local JSONL doesn't exist here. Don't fail — degrade:

- Work from what *is* durable: the PR comment's table (steps, attempts, exits), the PRD,
  the spec, and the diff. You can often still locate a context defect from the step that
  capped plus the failing output the STUCK comment includes.
- Ask the human to fetch the uploaded trace artifacts (a server/CI harness should upload
  the JSONL as workflow artifacts), or to re-run the resolver on the machine that built
  the PR.
- If neither is available, say so plainly and scope the evaluation to the durable evidence
  rather than guessing at trace content you can't see.
