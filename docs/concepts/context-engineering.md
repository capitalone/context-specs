# Context engineering

Context engineering is the practice of controlling what goes **into** — and what
stays **out of** — a coding agent's context window. It is the single biggest
lever you have when you build software with agents, and most other concepts in
Context Specs are an application of it at a larger scope.

## Why the window is the scarce resource

A coding agent does not "know" your codebase. At any instant it knows exactly
what is in its context window: the conversation so far, the files it has opened,
the tool output it has seen. That window is finite, and it degrades in three ways
that are easy to forget:

- **Context decay** — in a long session, older messages lose influence. The agent
  attends most to what is recent and quietly discounts what came before, so a plan
  laid out twenty tool calls ago is no longer really steering the work.
- **Context pollution** — left to roam, an agent retrieves context on its own: it
  greps, opens files, follows imports. Much of what it pulls in is irrelevant, and
  every irrelevant token crowds out a relevant one.
- **Compaction loss** — when the window fills, the session is summarized to make
  room, and you do not get to choose what is dropped. Critical details disappear
  and the agent "forgets" — not from carelessness, but because the bytes are gone.

None of these are quirks of a particular model. They are consequences of working
inside a finite window, and they intensify as a task grows — exactly when holding
a coherent picture matters most.

## The discipline: choose, don't dump

The intuitive move is to load everything up front — the whole architecture, every
convention, all the relevant files — and then start. That front-loads pollution
and makes compaction near-certain before the agent has done anything.

Context engineering is the opposite discipline: **the agent dynamically pulls the
context it needs, when it needs it, and the substrate it pulls from is the
filesystem.** Two techniques do most of the work:

- **Externalize the durable stuff.** Anything that must survive a long session —
  the plan, the conventions, the domain knowledge — lives in files on disk, not in
  the conversation. Files do not decay and are not compacted; the agent re-reads
  them precisely when they are relevant.
- **Progressive disclosure.** You hand the agent a *pointer* — a short, high-level
  description with a path — not dense detail. The agent reads the description
  first, decides whether it needs more, and only then opens the dense source. The
  window stays small and focused, holding just what the current step requires.

The filesystem is what makes this possible. A file is a unit of context the agent
can choose to load or ignore; a directory of well-named files is a menu it can
navigate just-in-time. Much of the skill of context engineering is the skill of
*organizing that menu* — so the right thing is one obvious read away and the wrong
thing is never accidentally in the window at all.

## Where it shows up in Context Specs

The same lever is pulled at every scale of the system:

| Scope | Application |
|---|---|
| One feature | A [spec](./spec-driven-development.md) externalizes the plan so it cannot decay or compact, and slices it so the agent only loads the piece it is working on. |
| Project knowledge | An [Expert](./long-term-memory.md) is curated knowledge pulled on demand instead of re-explained every session. |
| The whole run | The [dispatcher](./the-dispatcher.md) runs a fresh window per step, so no step inherits another's pollution. |
| Across features | [Long-term memory](./long-term-memory.md) keeps hard-won context alive so future features start from it. |
| You | The [human loop](./the-human-loop.md) is deliberate context engineering — deciding what the agents should have known and putting it where they will find it. |

Every layer answers the same question at its own scope: *what is the right context
here, and how does it reach the window at the right moment?*
