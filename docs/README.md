# Context Specs — the full story

This is the long-form documentation for Context Specs. The top-level
[README](../README.md) is the elevator pitch; this is the book.

It's written to be read **in order**. Each chapter ends where the next one
begins — by the last page you should see why a coding project, run well with
agents, stops looking like a codebase you type into and starts looking like a
**harness you tune**.

## The through-line

This project is **harness engineering in practice**. Harness engineering is
building a system — defined inputs, defined outputs — out of deterministic code
and probabilistic code, where the deterministic code invokes the probabilistic
code and controls the flow all the way to a guaranteed, well-defined output.

Here the input is a PRD with a runnable definition of done, and the output is
**a pull request that is either ready to merge or STUCK with a diagnosis** —
never "maybe." That output is also the system's feedback signal: every STUCK
and every review finding points at a piece of context to improve, and context
engineering — the right context at the right time — is the lever that moves the
ready-to-merge ratio up.

```
Context engineering          the lever: what enters an agent's window decides everything
        │
        ▼
Spec-Driven Development      the harness's short-term memory — plan one feature
        │                    outside the window, feed it back a slice at a time
        ▼
The agent harness            the system: deterministic code driving probabilistic
        │                    code from PRD to a guaranteed output (PR or STUCK)
        ▼
Long-term memory             the flywheel: the project learns every merge, and
        │                    long-term memory informs every future plan
        ▼
The human loop               the goals and the judgment: intent in, evaluation out
        │
        ▼
A mindset shift              your project has become a harness; your job is context
```

Two memory systems run through everything. The **Expert** (plus `AGENTS.md`) is
the project's *long-term* memory; the specs and slices are *short-term* memory —
the plan for one feature, informed by the long-term memory every time it's
written. Improve the long-term memory and every future feature plans better.
It's written back on two rhythms: **Reflection** in the hot path (after each
slice) and **/learn** off the hot path (after each merge — the system
consolidating what it learned while nothing is running, the way agents like
OpenClaw "dream").

And the whole thing is **goal-based**: `/intent` pins the goal down as a
runnable test, and the harness keeps invoking the model until the goal is met —
or the retry caps turn honest failure into STUCK.

## The chapters

1. **[Context engineering](./1-context-engineering.md)** — what it actually is,
   and why the context window is the scarce resource everything else is fighting
   over.
2. **[Spec-Driven Development](./2-spec-driven-development.md)** — the harness's
   short-term memory: experts, specs, temporal slicing, reflection, consensus
   validation. Usable on its own, no harness needed.
3. **[The agent harness](./3-the-agent-harness.md)** — the system itself: one
   harness repo driving N environments, a deterministic dispatcher, and why you
   can trust a machine to run it unattended.
4. **[Continuous improvement](./4-continuous-improvement.md)** — the flywheel:
   long-term memory, the destinations for a learned fact, and lints the agent
   cannot ship past.
5. **[The human loop](./5-the-human-loop.md)** — once the machine does the
   typing, what's left is the part only you can do: Understanding → Intent →
   Evaluate.
6. **[The mindset shift](./6-the-mindset-shift.md)** — the payoff. Your project
   is a harness now. Here's how the way you work changes.

### Reference

- **[Design invariants](./invariants.md)** — the properties the harness holds no
  matter what crashes, races, or restarts. Read this when you want to understand
  *why* the machine is safe to leave running. (Optional; you can also hand it to
  an agent to give it a deeper model of the harness.)

## Where the code lives

The deterministic half is the [`context-specs` CLI](../bin/) and the dispatcher
scripts under [`scripts/`](../scripts/); the probabilistic half ships as Agent
Skills under [`skills/`](../skills/). The chapters point at the specific skill,
script, or reference file that implements each idea, so you can read the story
and then go read the source.
