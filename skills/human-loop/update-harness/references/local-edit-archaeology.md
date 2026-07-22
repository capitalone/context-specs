# Why does this local edit exist?

You cannot recommend `take` — reverting someone's work — until you can say what it was
for (U1). The harness is a git repo, so the answer is usually recoverable in one command.

The report already includes the last commit that touched each attention file. That is a
starting point, not the answer: the last commit is often a bulk edit, and the *reasoning*
lives further back.

## The commands

```bash
git log -p --follow -- <path>        # full history of this file, with diffs
git log --format='%h %ad %s' --date=short -- <path>   # just the shape
git show <sha>                        # the whole commit — was this file incidental?
git log -S '<distinctive string>' -- <path>   # which commit introduced this exact line
```

`git log -S` is the sharp one. When a conflict is about a specific added line, it takes
you straight to the commit that added it, skipping every unrelated edit to the file.

## Reading the result

**A dedicated commit with a real message** is the good case. The message usually *is* the
rationale — quote it back. Note the date: an edit from last week and one from eighteen
months ago carry very different weight, because upstream may have since solved the same
problem properly.

**A bulk commit** ("tidy up skills", "sync") that touched thirty files is weak evidence
of intent. The edit may have been incidental — a reword, a typo fix — in which case
`take` is likely right and cheap. Check whether the change is *substantive* (a rule, a
constraint, a step) or *cosmetic*.

**The `init` commit** means the edit is not local at all — it is upstream content from
the version that was originally vendored, and the "conflict" is purely that upstream has
since changed it. `take` is almost always right. This is a common and reassuring finding.

**Empty or unhelpful history** — a squashed import, or the harness was re-initialized.
Say so plainly:

> I can't tell from the history why this was changed — it arrives in a bulk commit with
> no message. Do you remember, or should we treat it as incidental and take upstream?

Do not invent a rationale to fill the gap. A confident-sounding guess about why someone
changed something is worse than admitting the history is thin, because it will be
believed.

## Widen the search when the file is silent

The reason may be recorded somewhere other than this file's history:

- **The environment repos.** A harness edit often exists to serve one project's quirk.
  `grep` the registered environments' `AGENTS.md` and Expert for the same concept.
- **Sibling commits.** `git show` the whole commit — a skill edit made alongside a
  dispatcher change is part of one idea, and the other half may carry the explanation.
- **The human.** They are right there. Asking is faster than archaeology and often ends
  the question immediately.
