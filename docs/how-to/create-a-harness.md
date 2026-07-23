# Create a harness

The harness repo is the one repo you maintain that drives all your projects. You
create it once.

## Prerequisites

- Node.js 18+.
- `git`, `gh`, and the `claude` CLI on your `PATH`.

## Steps

Install the CLI, then scaffold your harness:

```bash
npm i -g context-specs
context-specs init my-harness
cd my-harness
```

`init` creates `my-harness` as **your own git repo** and vendors the canonical
content into it: the dispatchers under `scripts/`, the skills under `skills/`, the
subagents under `subagents/`, plus an `environments.toml` registry and an empty
`state/` for per-environment runtime data. It makes the initial commit for you.

Run `init` with no argument to scaffold in the current directory instead.

### The harness is yours

There is no `upstream` remote and no fork. The skills in `skills/` are **your
copies** — editing them is the intended workflow, and how the harness gets better
at your projects over time. `origin` stays free for your own remote.

Upgrades come later via [Update a harness](./update-a-harness.md), which 3-way
merges a new release against whatever you have changed.

### Where the CLI finds your harness

`context-specs` is installed globally and is stateless, so it resolves which
harness to act on at each invocation:

1. `CONTEXT_SPECS_HOME`, if set — the dispatchers export this when they call back
   into the CLI.
2. Otherwise it walks up from your current directory, looking for either a harness
   (`.context-specs/manifest.json`) **or a registered environment repo**, which
   points back at its harness through the skill symlinks `add` created.
3. Otherwise it errors rather than guessing.

So you can run harness commands from inside the harness *or* from any project you
have registered — which is where you will be most of the time. Tier 2's second half
depends on `context-specs add` having run for that project; until then, only the
harness works.

## Verify

```bash
context-specs doctor
```

`doctor` checks the harness itself, the registry, and every registered environment.
On a fresh harness it should report a healthy harness with no environments yet.

## Next

- [Add an environment](./add-an-environment.md) — register your first project.
