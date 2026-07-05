# Trace reading: from PR to evidence

This is the discipline behind Steps 1–3. The goal is not to *summarize* every session —
that's a transcript dump, and it tells you nothing. The goal is to read the few sessions
that fought, with the four lenses, until you can name which piece of context shaped each
decision the human cares about.

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

**Do not read the harness repo’s `state/<env>/sessions-<f>.tsv`.** It carries an extra `duration_s` column and
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

## The triage map (S7): where to START, not who to blame

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

## Classify, don't accumulate (feeds Step 4)

Every finding sorts into exactly one of two buckets — and the second is as valuable as the
first:

- **Context defect** — fixable: a missing Expert convention, a stale/missing AGENTS.md
  pointer, a skill whose own text steered wrong, an under-specified spec section. These
  become evals and/or context fixes.
- **Inherent difficulty** — the task was just hard; no context change would have helped.
  Name it and move on. Calling difficulty a "defect" over-fits memory with noise — the
  thing `/learn`'s reconcile justification bar and this skill's S4 both guard against.

## CI / remote degradation

If `resolve-sessions.sh` reports `MISSING` for a trace, the harness ran on another machine
(CI/server) and the local JSONL doesn't exist here. Don't fail — degrade:

- Work from what *is* durable: the PR comment's table (steps, attempts, exits), the PRD,
  the spec, and the diff. You can often still locate a context defect from the step that
  capped plus the failing output the STUCK comment includes.
- Ask the human to fetch the uploaded trace artifacts (a server/CI harness should upload
  the JSONL as workflow artifacts — see `observability-tooling.md`), or to re-run the
  resolver on the machine that built the PR.
- If neither is available, say so plainly and scope the evaluation to the durable evidence
  rather than guessing at trace content you can't see.
