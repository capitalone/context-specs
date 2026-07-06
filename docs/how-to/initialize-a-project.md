# Initialize a project

After a project is [registered](./add-an-environment.md), it still needs the
**Software 3.0** half — the pieces that can only be written by a model reading
*this* project. `/env-init` generates them.

## Prerequisites

- The project is registered as an environment.
- You are running `claude` inside the project directory.

## Steps

From inside the project:

```bash
cd ~/code/myapp
claude
> /env-init
```

[`/env-init`](../../skills/harness/env-init/SKILL.md) reads the codebase and
generates the project-owned artifacts as a single PR:

- **`AGENTS.md`** — the eager contract: a short map that points into the Expert
  (see [long-term memory](../concepts/long-term-memory.md)).
- **`/intent`** — a committed, project-tuned copy of the intent skill.
- **The Expert skeleton** — the project's [long-term memory](../concepts/long-term-memory.md),
  seeded and ready to grow.
- **`scripts/`** — the bootstrap and `local-checks.sh` gate.

## Review and merge

`/env-init` opens its work as a pull request. **Review and merge it** before
starting the harness — this is generated project code, and it is the foundation
every future feature builds on. Treat it like any other PR.

## Next

- [Express intent](./express-intent.md) — describe your first feature.
- [Run the harness](./run-the-harness.md) — start the loop and walk away.
