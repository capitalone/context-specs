# Harness engineering

Harness engineering is the discipline Context Specs is built on. Understanding it
is the fastest way to understand everything else, because every other concept is
an instance of it.

## What a harness is

Start with the equation:

> **Agent = Model + Harness**

The **model** is the probabilistic part: given a context window, it produces a
plausible next step. On its own it is a suggestion engine — capable, but with no
guarantees. It can drift, hallucinate, declare success it did not achieve, or
quietly lose the thread in a long session.

The **harness** is everything else wrapped around the model: the tools
it can call, the skills and prompts that shape each step, the control flow that
decides what runs next, and the checks that decide whether a step actually
succeeded. The harness makes the model's intelligence useful.

An agent is the two together. When people say "the agent did X," the interesting
engineering is almost always in the harness — the model is a component inside it.

## The discipline

> **Harness engineering is building a system — defined inputs, defined outputs —
> out of deterministic code and probabilistic code, where the deterministic code
> invokes the probabilistic code and controls the flow all the way to a
> guaranteed, well-defined output.**

Read that carefully, because each clause is load-bearing:

- **Defined inputs, defined outputs.** A harness is a function with a contract,
  not an open-ended chat. You know the shape of what goes in and the shape of what
  comes out.
- **Deterministic code and probabilistic code.** Both are first-class. The model
  supplies intelligence; the deterministic code supplies control, verification,
  and repeatability.
- **The deterministic code invokes the probabilistic code.** The control flow is
  in the reliable half. The model is called *by* the system; it does not steer
  the system. There is no LLM in the decision path deciding what happens next.
- **All the way to a guaranteed, well-defined output.** The system does not stop
  at "the model responded." It drives the process until it reaches one of a small
  set of defined terminal states — and it always reaches one.

## The guaranteed output: ready-to-merge or STUCK

In Context Specs, the input is a PRD with a runnable definition of done, and the
guaranteed output is **a pull request in one of exactly two finished states**:

- **Ready to merge** — the feature is built and every check passed.
- **STUCK** — the system could not finish honestly, and it hands you a diagnosis
  of what blocked it instead of faking success.

Both are *finished* states. The system never returns "maybe," never returns a
half-built branch with no verdict, and never claims done when it is not. That
guarantee is the whole point of engineering a harness rather than prompting a
model and hoping. The mechanics of how "done" is proven, and what a STUCK hands
you, are covered in [the output contract](./output-contract.md).

## How the rest of the system follows from this

Everything in Context Specs is harness engineering applied at a particular scope:

- The reliability of each step comes from [context engineering](./context-engineering.md) —
  the lever that decides what the model reasons over.
- The system's shape is [one harness driving N environments](./two-tier-architecture.md).
- The deterministic control flow is [the dispatcher](./the-dispatcher.md): pure
  code, no model in the decision path.
- The guaranteed output is defined by [the output contract](./output-contract.md).
- The harness gets better over time through [continuous improvement](./continuous-improvement.md) —
  you operate on the *system*, not the individual feature.
- And [the human loop](./the-human-loop.md) is the part of the job a harness
  cannot take: deciding what to build and judging whether what came back is right.
