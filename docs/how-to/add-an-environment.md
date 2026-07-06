# Add an environment

Registering a project as an **environment** connects it to your harness. This is
the deterministic half of setup — the CLI does it without reading your project's
code.

## Prerequisites

- A [harness repo](./create-a-harness.md).
- A target project that is a git repository.

## Steps

From inside your harness repo:

```bash
context-specs add ~/code/myapp            # or:  add ~/code/myapp --name myapp
```

`add` does three project-agnostic things:

1. **Symlinks the canonical skills** from the harness repo into the project's
   `.claude/skills/` (gitignored — they belong to the harness, not the project).
2. **Writes `.gitignore` entries** so those symlinks and the harness's runtime
   artifacts stay out of the project's history.
3. **Registers the project** in the harness's `environments.toml`.

Two skills are deliberately *not* symlinked, because they are the project's own
[developer-owned levers](../concepts/two-tier-architecture.md#the-two-developer-owned-levers):
`/intent` and the Expert. Those are generated into the project in the next step.

## Verify

```bash
context-specs doctor
```

The project should now appear as a registered environment.

## Re-linking

The skill symlinks live in worktrees the harness creates and tears down, so they
are re-created automatically by `bootstrap-worktree.sh`. If you ever need to
recreate them by hand (e.g. in a fresh clone), run:

```bash
context-specs link ~/code/myapp
```

`link` is idempotent.

## Next

- [Initialize a project](./initialize-a-project.md) — generate the Software 3.0
  half (`AGENTS.md`, `/intent`, the Expert, checks).
