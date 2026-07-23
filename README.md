# Context Specs

**Applied harness engineering.**

*Harness engineering is building a system — defined inputs, defined outputs — out of
deterministic code and probabilistic code, where the deterministic code invokes the
probabilistic code and controls the flow all the way to a guaranteed, well-defined
output.*

Context Specs is that system for coding — **autonomous** and **goal-based**. You
express intent (your goal); the harness plans the feature with **Spec-Driven
Development** and implements it slice by slice, on its own; you always get back a
pull request (your guaranteed output) — either **ready to merge**, or **STUCK with a
diagnosis** of what blocked it.

## The point isn't one PR — it's the system that produces them

You work at the level of the **system that builds features**, not the individual
feature. That distinction is the whole idea:

- **Fix a piece of code** and you ship that one feature. Nothing else changes; the
  next feature starts where the last one did.
- **Fix a context gap** — a thin definition of done, a missing piece of long-term
  memory, an environment the agent couldn't navigate — and *every future feature*
  gets better. You fixed a class of failure, not an instance.

You do both, but context-gap fixes are the main lever, because they compound. As you
pull it, more PRs come back ready-to-merge and fewer come back stuck.

So the craft shifts. Instead of typing features, you do **context engineering**: set
up environments agents can work in, pin goals to a real definition of done, and grow
the project's long-term memory — the accumulated knowledge that tells the agent how
to plan every feature. Getting that right is what turns AI slop into PRs you can
actually merge. You operate on the harness; the harness operates on the code.

## One harness, many projects

You maintain **one** harness repo and point it at any number of project repos. Improve
the harness once and every project inherits it.

```mermaid
flowchart LR
  H["Your harness\n(one repo you tune)"]
  H --> A[project A]
  H --> B[project B]
  H --> C[project C]
```

How the two tiers divide, how the deterministic dispatcher drives each project, and
why it's safe to leave running are all in the docs — this README stays deliberately
short.

## Quickstart

```bash
# 1 · Create your harness (one repo that drives all your projects — and it's yours)
npm i -g context-specs
context-specs init my-harness
cd my-harness

# 2 · Register a project as an environment
context-specs add ~/code/myapp

# 3 · Generate the project-specific pieces, then merge the PR it opens
cd ~/code/myapp && claude
> /env-init          # AGENTS.md, /intent, the Expert, checks, bootstrap

# 4 · Describe a feature, then walk away
> /intent            # idea → PRD + runnable definition of done
context-specs start  # right here in the project — the environment is implied
```

From there you live in a three-beat cycle — **express intent, the harness builds, you
evaluate**. The middle beat is SDD, run end to end without you:

```mermaid
flowchart LR
  Intent["/intent\nyou express intent"] --> Plan["spec-planning"]
  Plan --> Val["spec-validate"]
  Val --> Impl["implement slices"]
  Impl --> PR["PR\nready to merge · STUCK"]
  PR --> Eval["/evaluate-pr\nyou understand & merge"]
  Eval --> Learn["/learn\nproposes memory updates"]
  Learn --> Intent
```

`context-specs status` shows every project's features and phases; `run` does one
foreground pass; `logs <env> -f` follows the loop; `doctor` checks the wiring.

## Specs are short-term memory

Most SDD tooling stops at the spec: a human drives the spec, then a human drives the
implementation. Here the spec is the harness's **short-term memory** — and the harness
runs it all the way to a PR.

A spec is true *right now*, about *this* feature. `specs/<feature>/mainspec.md` is the
end state you work backward from; ordered slices under `specs/<feature>/slices/` are
the path to it, each naming the real files it touches. The agent is fed one slice at a
time, so its window stays small and the plan can't decay or compact away — after a
compaction it just re-reads the spec. Once the feature ships, the spec stops steering
anything and survives only as a record.

Durable knowledge lives elsewhere, in **long-term memory**: the Expert, `AGENTS.md`,
and lints. The bridge between them is **Reflect** — at the end of each slice, once the
code is green, the agent writes back only what is genuinely durable. The bar is high;
most slices reflect nothing. Keeping the two separate is what lets each do its job:
specs stay lean and disposable, long-term memory stays curated and permanent.

## Long-term memory & continuous learning

Specs are disposable; **long-term memory** is what the harness keeps — the durable,
cross-feature knowledge that plans every feature, and it lives in two shapes. The
**Expert** is the dense knowledge: architecture, patterns, how things get verified
here — pulled into a window only when **spec-planning** (your short-term memory)
consults it. **`AGENTS.md`** is loaded into every agent that touches a folder, so it
stays a short map that *points into* the Expert rather than duplicating it. And the
most durable thing a project owns is the set of **lints** it grows — a learned rule
turned into a script the agent *cannot ship past*, with the fix in the error message.

This memory is **yours** — it is how you gain leverage. Two automated helpers keep it
fed as you ship: **Reflect** writes back only what a green slice proved durable, and
[`/learn`](./docs/concepts/long-term-memory.md) reads each *merged* diff and opens its
own PR against your memory — adding what the merge taught, retiring what it
invalidated. Both are good, and both run without you.

But the highest-leverage move is the one you drive yourself:
[`/improve-context`](./docs/how-to/improve-context.md). The automated helpers file in
behind the merged code; when you sit down with `/improve-context` you can *steer* —
going deep on the Expert and on **agent legibility**, making the environment navigable
and the intent unambiguous, so every future plan starts from a better place than a diff
alone could teach. That is where your leverage compounds fastest.

That is the flywheel. Every feature that merges leaves the harness knowing a little
more than it did, so the next feature is planned by a smarter harness. Which circles
back to the opening claim:

**A codebase you type into is a constant cost. A harness you tune is an appreciating
asset — each feature leaves it a little more capable of building the next one. Massive
leverage.**

## Documentation

- **[How Context Specs works](./docs/overview.md)** — the narrative tour, start to
  finish.
- **[Spec-Driven Development](./docs/concepts/spec-driven-development.md)** — how the
  harness builds one feature: mainspec, slices, validation, Reflect.
- **[Core concepts](./docs/README.md#core-concepts)** — harness engineering, context
  engineering, the dispatcher, memory, continuous improvement, the human loop.
- **[How-to guides](./docs/README.md#how-to-guides)** — set up, run, and improve the
  harness.
- **[Design invariants](./docs/reference/invariants.md)** — the proof it's safe to
  leave running.

## License

Apache 2.0
