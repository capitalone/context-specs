# Context Specs — the full story

This is the long-form documentation for Context Specs. The top-level
[README](../README.md) is the elevator pitch; this is the book.

It's written to be read **in order**. Each chapter ends where the next one
begins — by the last page you should see why a coding project, run well with
agents, stops looking like a codebase you type into and starts looking like a
**harness you tune**.

## The through-line

One idea runs under everything here: **the right context at the right time.**
What enters an agent's context window is the biggest lever you have. Context
Specs is that lever, pulled at three levels — each one building on the one
before it:

```
Context engineering          the idea: an agent choosing what enters its window
        │
        ▼
Spec-Driven Development       Layer 1 — the idea, applied to building one feature
        │
        ▼
The agent harness            Layer 2 — the project runs that loop for you, and
        │                              gets better every merge
        ▼
The human loop               Layer 3 — freed from typing, you improve the harness
        │
        ▼
A mindset shift              your project has become a harness; your job is context
```

Each layer is usable without the ones above it. Spec-Driven Development needs no
harness. The harness needs no human-loop discipline to run. The value compounds
as you climb — but you can stop on any rung.

## The chapters

1. **[Context engineering](./1-context-engineering.md)** — what it actually is,
   and why the context window is the scarce resource everything else is fighting
   over.
2. **[Spec-Driven Development](./2-spec-driven-development.md)** *(Layer 1)* — how
   Context Specs applies context engineering to a single feature: experts, specs,
   temporal slicing, signal, consensus validation. The foundation, usable on its
   own.
3. **[The agent harness](./3-the-agent-harness.md)** *(Layer 2)* — file a PRD,
   walk away, come back to a finished PR. The autonomous loop, and why you can
   trust a machine to run it unattended.
4. **[Continuous improvement](./4-continuous-improvement.md)** *(Layer 2)* — how
   the harness gets better every merge: long-term memory, the four destinations
   for a learned fact, and lints the agent cannot ship past.
5. **[The human loop](./5-the-human-loop.md)** *(Layer 3)* — once the machine does
   the typing, what's left is the part only you can do: Understanding → Strategy →
   Intent → Evaluate.
6. **[The mindset shift](./6-the-mindset-shift.md)** — the payoff. Your project is
   a harness now. Here's how the way you work changes.

### Reference

- **[Design invariants](./invariants.md)** — the properties the harness holds no
  matter what crashes, races, or restarts. Read this when you want to understand
  *why* the machine is safe to leave running. (Optional; you can also hand it to
  an agent to give it a deeper model of the harness.)

## Where the code lives

Everything described here ships as Agent Skills under
[`skills/`](../skills/). The chapters point at the specific
skill, script, or reference file that implements each idea, so you can read the
story and then go read the source.
