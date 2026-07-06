# Spec-Driven Development: the harness's short-term memory

Spec-Driven Development (SDD) is how the harness builds one feature well. It is
best understood as **[context engineering](./context-engineering.md) applied to a
single feature** — and as the harness's **short-term memory**: a point-in-time
plan for one feature, not a durable store of project knowledge.

## SDD is a context-engineering technique

Give an agent "add search to the app" and it does something reasonable: it greps,
opens files to infer conventions, guesses how you test. On a small change that is
fine. On a large feature it accumulates — halfway through, the window is full of
half-relevant code the agent retrieved on its own, the original intent has decayed,
and the next compaction is poised to drop the part it actually needed.

SDD fixes this by doing the thinking **outside** the context window first and
persisting it as structured files on disk. The plan does not sit in the
conversation where it decays; it sits in files the agent pulls from. That is the
core context-engineering move: **the right context reaches the window at the right
time because the agent dynamically pulls the slice it needs, rather than carrying
the whole feature in-window the entire way.** The plan cannot decay or compact
away, because it was never in the conversation to begin with — after a compaction
the agent simply re-reads the spec and continues.

## Short-term memory, not long-term memory

This is the distinction that keeps the two memory systems from blurring:

> A spec is **short-term memory**: it exists to build **one feature**, and it is
> a **point-in-time** artifact. It is not where the project's durable knowledge
> lives.

While the feature is being built, the spec is the agent's working memory —
focused entirely on this one feature, disclosed a slice at a time. Once the
feature is complete, the spec **stops steering anything**. It does not roll up
into a growing knowledge base. Its remaining value is as a *record*:

- **Reviewing the code** — the spec says what was intended, so a reviewer can
  check the diff against it.
- **Evals** — a completed spec and its build trail are raw material for capturing
  regression checks over the harness's own behavior.
- **Understanding the agent's decisions** — when you want to know *why* the agent
  built it this way, the spec is the reasoning it worked from.

Durable, cross-feature knowledge — architecture, patterns, hard-won constraints —
does not belong in a spec. That is [long-term memory](./long-term-memory.md), and
it lives in the Expert. Keeping short-term and long-term memory separate is what
lets each do its job: the spec stays lean and disposable; the Expert stays curated
and permanent.

## The artifacts SDD produces

When [`/spec-planning`](../../skills/sdd/spec-planning/SKILL.md) runs, the planner
researches the actual codebase (grounding the plan in reality, not guesswork),
pulls in any Experts whose triggers match, and writes the plan to disk as two
kinds of file:

- a **mainspec** (`specs/<feature>/mainspec.md`) — the complete end state, the
  north star you work backward from;
- ordered **slices** (`specs/<feature>/slices/`) — temporal chunks of intent, each
  a coherent unit of work focused on *what* and *why*.

What goes *into* a spec is itself disciplined context engineering — precise
BEFORE/AFTER file paths, type contracts first, DO/DON'T counterexamples, narrative
temporal flows, and forward-looking requirements — so the agent can execute
without guessing.

## Temporal slicing: progressive disclosure, structurally

Slices are ordered by *intent* (what needs to happen), not by *component*
(frontend/backend), because features have a natural dependency order and slicing
by intent preserves it. Each slice depends on prior slices and declares contracts
for future ones.

That ordering does two jobs at once. For the implementer it is progressive
disclosure made structural: the agent is fed **only the current slice**, never the
whole feature, so its window stays small and focused. For the orchestrator, the
dependencies define execution order — every mainspec carries a **Slice Dependency
Map** that says which slice to implement next.

## Validation: consensus before code

A plan has blind spots, so
[`/spec-validate`](../../skills/sdd/spec-validate/SKILL.md) hardens it before a
line of code is written: multiple independent Opus subagents review the spec, and
agreement is graded (3/3 = very high confidence, down to 1/3 = a judgment call).
Relevant Experts add domain-specific review. Findings are consolidated and the
impactful ones applied **in place** — validation sharpens the plan, it does not
bounce it back to start over. Independent reviewers have *different* blind spots;
consensus scoring turns that into a confidence signal instead of a coin flip.

## Implementation: write, verify, reflect

[`/implement-slice`](../../skills/sdd/implement-slice/SKILL.md) implements one
slice in three beats: write the code, verify it with unit tests, then **Reflect**.
Reflect is the one that reaches *out* of short-term memory: once the code is green,
the agent compares what it just learned against the project's long-term memory and
— only when there is a real, durable lesson — writes it back into the Expert. This
is the one bridge from a feature's short-term memory to the project's long-term
memory, and the bar is deliberately high; most slices reflect nothing.

[`/implement-mainspec`](../../skills/sdd/implement-mainspec/SKILL.md) orchestrates
the whole feature: it reads the Slice Dependency Map and delegates each slice, in
dependency order, to a focused subagent — committing each to the feature branch as
it lands. One slice at a time keeps the orchestrator's window lean and every
commit reviewable.

## Related

- [Context engineering](./context-engineering.md) — the lever SDD applies.
- [Long-term memory](./long-term-memory.md) — the durable counterpart; where
  Reflect writes.
- [The dispatcher](./the-dispatcher.md) — runs the SDD loop autonomously, one step
  per fresh window.
