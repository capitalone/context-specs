# Create a harness

The harness repo is the one repo you maintain that drives all your projects. You
create it once.

## Prerequisites

- Node.js (for `npx`).
- `git`, and the `claude` CLI on your `PATH`.

## Steps

Create (or adopt) a harness repo from the template:

```bash
npx context-specs init my-harness
cd my-harness
```

`init` scaffolds the [two-tier layout](../concepts/two-tier-architecture.md): the
`context-specs` CLI under `bin/`, the dispatchers under `scripts/`, the canonical
skills under `skills/`, and an empty `state/` for per-environment runtime data. If
you point `init` at an existing repo, it *adopts* it — adding the harness pieces
without disturbing what is already there.

## Verify

```bash
context-specs doctor
```

`doctor` checks the harness itself, the registry, and every registered environment.
On a fresh harness it should report a healthy harness with no environments yet.

## Next

- [Add an environment](./add-an-environment.md) — register your first project.
