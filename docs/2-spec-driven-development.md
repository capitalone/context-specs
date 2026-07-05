# Chapter 2 — Spec-Driven Development

*Context engineering, applied to building one feature — the harness’s short-term memory.*

The smallest complete unit of work is a feature: take an idea, turn it into code
that works. Spec-Driven Development (SDD) is what happens when you treat that as
a context-engineering problem rather than a typing problem.

The question from Chapter 1 — *what is the right context, and how does it reach
the window at the right moment?* — has a concrete answer here, and Context Specs
ships it as a handful of Agent Skills. **This layer needs nothing else in this
book.** You can link or copy these skills into any project today and drive them by hand, with
or without the harness in later chapters.

## The problem SDD solves

Give an agent "add search to the app" and it does something reasonable: it
greps, opens files to infer your conventions, makes a guess at how you test
things. On a small change that's fine. On a large feature it accumulates —
halfway through, the window is full of half-relevant code the agent retrieved on
its own, the original intent has decayed, and the next compaction is poised to
drop the part it actually needed.

SDD fixes this by doing the thinking **outside** the context window first, and
persisting it as structured files the agent reads progressively. Two artifacts
carry that externalized thinking — and one mechanism carries the knowledge that
shapes them.

## The Expert — define knowledge once, use it everywhere

![Experts](../experts.png)

Most of what makes a feature "right" isn't in the feature request — it's in your
project's accumulated knowledge: how this codebase is layered, how it tests new
routes, which patterns to reach for and which to avoid. Re-explaining that every
session is exactly the context decay Chapter 1 warned about.

An **Expert** externalizes it as a progressively-disclosed knowledge module.
Your project's own Expert — its long-term memory — is seeded as a skeleton by
`/env-init` and grows from there (Chapter 4); you can add further Experts for
external domains (an internal library, a framework) the same way, as
`expert-{name}/` skills alongside it:

```
expert/                # (or expert-{name}/ for an outside domain)
├── SKILL.md           # high-level index + routing table, read first
└── references/        # dense knowledge, one topic per file, read on demand
    └── {prefix}-{topic}.md
```

The Expert is the menu from Chapter 1 made concrete: a short `SKILL.md` the agent
sees first, pointing into dense `references/` it loads only on demand. Define the
knowledge **once**, and it flows automatically through every phase below — you
never paste it into a prompt again.

Two properties make Experts more than a docs folder:

- **Composable, not hardcoded.** Multiple Experts activate for one feature. A
  React Expert and a DynamoDB Expert both contribute when you build a full-stack
  feature, each curating its slice of the context. Add or remove Experts without
  touching any existing skill; organizations layer in private Experts for
  internal libraries the same way.
- **It curates before, and sharpens after.** An Expert curates context *before*
  you write code; then the **Reflect** step at the end of each slice feeds new
  lessons — a fresh pattern, a spec that fought the codebase — back into it, so the
  Expert gets a little better every time the project builds. (An Expert can also
  ship an optional runtime signal script, but a slice's unit tests are the default
  proof it works.)

## Specs — planning lifted out of the window

When you run [`/spec-planning`](../skills/sdd/spec-planning/SKILL.md),
the planner researches the actual codebase (grounding the plan in reality, not
guesswork), pulls in any Experts whose triggers match, and writes the plan to
disk as two kinds of file:

- a **mainspec** (`specs/<feature>/mainspec.md`) — the complete end state, the
  north star you work backward from;
- ordered **slices** (`specs/<feature>/slices/`) — temporal chunks of intent,
  each a coherent unit of work focused on *what* and *why*.

This is the answer to context decay and compaction loss: the plan lives in files,
so it can't be forgotten or summarized away. After a compaction the agent simply
re-reads the spec and "remembers."

What goes *into* a spec is itself disciplined context engineering — these are the
practices that make a spec something an agent can execute without guessing:

- **BEFORE/AFTER with precise file paths** — exact current state vs. desired
  state, so there's no ambiguity to resolve by greping.
- **Type contracts first** — define interfaces and schemas up front; sometimes an
  entire slice is nothing but types.
- **DO/DON'T counterexamples** — one good example, one bad, with *why* the bad one
  fails.
- **Narrative temporal flows** — Mermaid sequence diagrams and flowcharts showing
  causality across layers.
- **Forward-looking requirements** — each slice notes what future slices will
  need, preventing rework.

## Temporal slicing — progressive disclosure, structurally

Why slice by *intent* (what needs to happen) rather than by *component*
(frontend/backend)? Because features have a natural dependency order, and slicing
by intent preserves it. Each slice depends on prior slices and declares contracts
for future ones.

That ordering does two jobs at once. For the implementer, it's progressive
disclosure made structural: the agent is fed **only the current slice**, never
the whole feature, so its window stays small and focused. For the orchestrator,
the dependencies define the execution order. Every mainspec carries a **Slice
Dependency Map** (a table plus a Mermaid graph), which the orchestrator reads to
implement slices in dependency order, one at a time.

## Validation — consensus before code

A spec is a plan, and plans have blind spots. [`/spec-validate`](../skills/sdd/spec-validate/SKILL.md)
hardens it before a line of code is written, in three phases:

1. **Multi-agent consensus.** Spawn 3+ Opus subagents that independently review
   the spec. Agreement is signal — and it's graded, not binary:

   | Consensus | Confidence | Reading |
   |-----------|------------|---------|
   | 3/3 found | Very high | Real issue — fix it |
   | 2/3 found | High | Likely real — should fix |
   | 1/3 found | Medium | Could be a false positive — judgment call |

2. **Expert review.** The relevant Experts validate the spec for domain-specific
   anti-patterns, library misuse, and gaps a general reviewer would miss.
3. **Consolidation.** Findings are deduplicated and grouped by consensus; the
   impactful ones are applied **in place** to the spec files. Validation sharpens
   the plan; it doesn't bounce it back to start over.

A single reviewer has blind spots; independent reviewers have *different* blind
spots, and consensus scoring turns that into a confidence signal instead of a
coin flip.

## Implementation — write, verify, reflect

[`/implement-slice`](../skills/sdd/implement-slice/SKILL.md) implements one slice
in three beats: write the code, verify it with unit tests, then **Reflect**. The
first two are the obvious ones. Reflect is the one that compounds: once the code
is green, the agent loads the Expert, compares what it just learned against what
the project already knows, and — only when there's a real lesson — writes it back
as a new or corrected reference. Where the Expert shapes context *before*
implementation, Reflect updates it *after*, so the curation and the learning are
two halves of the same module. The bar is deliberately high: most slices reflect
nothing.

[`/implement-mainspec`](../skills/sdd/implement-mainspec/SKILL.md)
orchestrates the whole feature: it reads the Slice Dependency Map and delegates
each slice, in dependency order, to a focused `slice-implementer` subagent —
committing each to the feature branch as it lands. One slice at a time keeps the
orchestrator's window lean and every commit reviewable.

The feedback loop runs **per slice**, not just at the end — the agent knows
whether it's on track as it goes, not after.

## What you have at the end of this chapter

A repeatable way to take one feature from idea to working code while keeping the
agent's window full of exactly the right context and nothing else: knowledge
defined once and pulled on demand, planning externalized and disclosed
progressively, validation by consensus, implementation verified by unit tests
and fed back through Reflect. All of
it framework-agnostic, all of it usable on its own.

---

But notice what you're still doing: you invoke `/spec-planning`, then you invoke
`/spec-validate`, then you invoke `/implement-mainspec`. You're driving every
step, one feature at a time, sitting at the keyboard the whole way through.

The loop is good. What if the *project itself* ran it for you — picked up a
feature request, planned it, validated it, implemented it, and handed you back a
finished pull request while you did something else?

That's the leap from a skill library to a **harness**.

→ [Chapter 3 — The agent harness](./3-the-agent-harness.md)
