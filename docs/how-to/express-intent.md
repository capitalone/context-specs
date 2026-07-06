# Express intent

`/intent` is how you turn an idea into work the harness can build. It produces a
PRD paired with a **runnable definition of done** — the harness's input and its
goal. This is one of the three places [you steer the machine](../concepts/the-human-loop.md#the-three-places-you-steer).

## Prerequisites

- The project is [initialized](./initialize-a-project.md) (`/intent` and the Expert
  exist).
- You are running `claude` inside the project.

## Steps

```bash
cd ~/code/myapp
claude
> /intent
```

Then describe what you want. [`/intent`](../../skills/human-loop/intent/SKILL.md)
will:

1. **Elicit the outcome, not the solution.** If you describe an implementation
   ("add a `/api/search` endpoint"), it surfaces the need underneath ("readers
   can't find a post by title") and the observable outcome that would satisfy it.
2. **Ask "how would we know that's true?"** of each outcome, converting a wish into
   a sharp prose criterion *and* a concrete check.
3. **Draft the runner for you.** You do not write `run-prd-test.sh` — the Expert
   drafts it so verification is grounded in how the project actually works, and you
   review it.
4. **Confirm the test fails for the right reason.** Before committing, `/intent`
   runs the script against today's unbuilt code and checks that it fails because the
   behavior is *genuinely absent* — not because of a typo or missing dependency.

## What you get

Two coupled artifacts on a `prd/<author>/<feature>` branch:

- `prds/<feature>/prd.md` — why it exists and what "done" means.
- `prds/<feature>/run-prd-test.sh` — the executable definition of done; exits 0 when
  the feature is built.

The moment you confirm the PRD, it lands on the queue branch and the harness can
claim it. See [the output contract](../concepts/output-contract.md) for how that
runner becomes the goal the loop drives toward.

## Tips

- **Spend your judgment here.** How well a project turns an idea into a good PRD is
  one of the biggest levers it has. A thin definition of done is the most common
  cause of a STUCK later.
- **Tune the skill.** `/intent` is project-owned; adjust it to how your team
  actually expresses features.

## Next

- [Run the harness](./run-the-harness.md) — let the loop build it.
