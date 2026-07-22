# Update a harness

Pull a newer context-specs release into your harness without losing the edits you
have made to it.

## The problem this solves

Your harness is vendored, not forked: `skills/`, `subagents/` and `scripts/` are
**your copies**, and you are expected to have changed them. A new release changes
some of those same files. Neither overwriting your work nor skipping the release is
acceptable, so `update` performs a real **3-way merge**.

It can do that because `init` kept a pristine copy of everything it vendored in
`.context-specs/base/`. That is the common ancestor: with it, "did you edit this?"
and "did upstream change this?" are separate, answerable questions.

## Prerequisites

- A clean working tree in the harness. `update` refuses otherwise — that is what
  makes `git checkout .` a complete undo.
- No running supervisors (`context-specs stop --all`). `update` rewrites `scripts/`,
  which the dispatchers are executing.

## Steps

```bash
npm i -g context-specs@latest
cd my-harness
context-specs update
```

Each vendored file resolves to exactly one outcome:

| Situation | What happens |
|---|---|
| Upstream did not touch it | Nothing. Your edits are irrelevant here, and it is not reported. |
| You never edited it | Overwritten with the new version. |
| Upstream removed it, you had not edited it | Removed. |
| Upstream removed it, you had edited it | **Kept**, and reported. |
| You deleted it, upstream still ships it | Stays deleted, and reported. |
| Both changed, different parts of the file | Merged automatically. |
| Both changed, overlapping lines | **Conflict** — markers written into the file. |
| Both changed a `.md`, merged cleanly | Merged, but flagged for **semantic review**. |

That last row is the one a merge tool cannot handle alone. Skills are prose that
instructs an agent, so two edits can merge without a single conflict and still
contradict each other — a new rule in `## Hard nevers` that the rewritten flow above
now violates. git will never notice. A human (with `/update-harness`) has to read it.

Afterwards, every registered environment is automatically re-linked, so skills added
or removed by the release are reflected in each project's `.claude/skills/` and its
managed `.gitignore` block.

## Resolve what is left

```bash
claude
> /update-harness
```

The skill reads `.context-specs/update-report.md`, reconstructs *why* each local edit
exists from your harness's own git history, and walks each file with a
recommendation — keep, take, merge, or customize — naming what each one costs. See
[the update-harness skill](../../skills/human-loop/update-harness/SKILL.md).

## Verify

```bash
context-specs doctor
```

`doctor` fails on any unresolved conflict markers in vendored files and syntax-checks
every vendored shell script — a badly resolved dispatcher would otherwise break
silently at the next tick.

## If it goes wrong

The harness is your git repo and the tree was clean when you started:

```bash
git diff        # review the entire update
git checkout .  # throw all of it away
```

## Notes

- **`update` is safe to re-run.** It is a no-op when the harness already matches the
  installed CLI version.
- **An interrupted update resumes.** `.context-specs/base/` advances per file and the
  manifest is written last, so re-running finishes the job rather than corrupting it.
- **Conflicts advance the base too.** `BASE` means "what upstream last handed you".
  The conflict markers live in your working file, where you and the skill can see them.
