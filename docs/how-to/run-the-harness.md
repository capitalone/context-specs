# Run the harness

Once a project is [initialized](./initialize-a-project.md) and has at least one
[PRD](./express-intent.md) on the queue, the harness can build unattended. This
guide covers the CLI that schedules [the dispatcher](../concepts/the-dispatcher.md).

## Start the loop and walk away

The usual place to run this is **the project you are working in** — the CLI finds the
harness from there, and the environment is implied:

```bash
cd ~/code/myapp
context-specs start            # targets myapp
```

From the harness, say which one — or all of them:

```bash
cd ~/my-harness
context-specs start myapp      # one environment
context-specs start --all      # every registered environment
```

With exactly one environment registered, the bare form works from the harness too.
Anything the CLI infers is printed to stderr (`targeting 'myapp' (inferred from your
current directory)`), so a bare command never quietly acts on the wrong project.

`start` runs one background supervisor per environment — a **build loop** and a
**memory loop**. Each environment gets its own supervisor, lock, and state, so
running several projects at once is the default, not a mode.

The scheduling protocol is just the dispatcher's exit code: **0** means idle (sleep
the interval, default 5 minutes), **10** means "work advanced" (re-invoke
immediately, so a claimed PRD marches through planning → validate → implement at
machine speed). Errors back off exponentially, and a STUCK feature reports idle so a
stuck environment never hot-loops.

Stop them with:

```bash
context-specs stop            # same target rules;  stop --all for everything
```

## Run one pass in the foreground

When you would rather watch than daemonize:

```bash
context-specs run             # one tick, drained to idle, no daemon
context-specs run --learn     # run the memory loop instead of the build loop
```

`run` drains a single environment, so it takes a name (or infers one) but rejects
`--all`.

## Observe

```bash
context-specs status              # one table: every environment's features and phases
context-specs status --fetch      # fetch refs first, then show
context-specs logs -f             # follow the build loop of the environment you're in
context-specs logs myapp --learn  # the memory loop's logs, named explicitly
context-specs doctor              # check the harness, registry, and every environment
```

`status` applies the dispatcher's liveness gate — it shows active features, not
ones already merged or closed. Both `status` and `doctor` are deliberately
**fleet-wide**: they show every environment no matter where you run them, because
the thing you most need to see is a STUCK feature in the project you *aren't*
looking at.

## What comes back

Every feature ends in one of two states — **ready to merge** or **STUCK** — per
[the output contract](../concepts/output-contract.md). From here:

- A ready PR → [evaluate it](./evaluate-a-pr.md).
- A STUCK feature → [unstick it](./unstick-a-feature.md).

## Scaling beyond a laptop

The dispatcher is the portable part: the same script a laptop supervisor invokes
can be driven by cron or a server runner. When a team outgrows local laptops, they
move the *scheduler* and keep everything else — an upgrade path, not a rewrite.
