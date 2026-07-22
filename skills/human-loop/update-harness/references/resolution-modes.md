# The four resolutions

Every attention item ends in exactly one of these. The point of naming them is that each
has a *different cost*, and the human should hear the cost before they choose (U3).

## keep — your version wins

The upstream hunk is discarded for this file.

**Costs:** you do not get whatever upstream fixed there, and — the part people forget —
**the conflict recurs.** BASE has advanced to upstream's version, so next release the
merge is your-version-vs-their-newer-version all over again. Keeping is not free; it is a
standing tax you pay every update.

**Right when:** the upstream change is genuinely wrong for this project, or the local
edit encodes something upstream cannot know (a house convention, a monorepo layout, a
compliance rule).

## take — upstream wins

The local edit is reverted for this file.

**Costs:** whatever the local edit was solving comes back. This is why U1 matters — if
you cannot articulate what is being given up, you are not ready to recommend `take`.

**Right when:** the local edit was a workaround for something upstream has now fixed
properly, or was incidental (a typo fix, a reword) rather than intentional. Check the
history: an edit made in a bulk "tidy up" commit is far more likely to be incidental than
one with its own commit and a reason in the message.

## merge — both, reconciled by hand

You write the version that carries both intents. Usually the highest-value answer and
almost always available for prose, because two edits to a SKILL.md rarely disagree about
*everything* — they disagree about one sentence.

**Costs:** a real decision now, and a file that is neither side's, so the next update
3-ways against a version upstream has never seen. That is fine and expected; it is what
BASE is for.

**Right when:** both changes are correct in their own terms. Most conflicts are this.

## customize — a deliberate, permanent fork of this file

Like `keep`, but *declared*. You are saying this file is now yours, and you expect to
reconcile it every release rather than being surprised by it.

**Costs:** the same recurring reconciliation as `keep`, but nobody is surprised by it.

**Right when:** the file has drifted far enough that merging is no longer meaningful —
your `/intent` prompts, an Expert format tuned to your domain, a dispatcher step your
project does differently.

**Say this out loud when you recommend it:** customizing is the *supported* path, not a
hack. `.context-specs/base/` still advances to upstream on every update, so you keep
getting a real 3-way merge against the newest version — you just accept that you are the
one deciding, every time. The escape hatch is deleting your version, which re-adopts the
canonical one on the next update.

---

## Hackable seam

Projects accumulate rules about what must never take upstream — a dispatcher step wired
to internal infrastructure, an Expert format other tooling parses, a `/intent` flow tuned
to a specific PRD template. If this harness has such rules, record them here so future
runs of this skill recommend `keep` or `customize` for those paths without re-litigating:

```
# Never take upstream:
#   skills/human-loop/intent/       — our PRD template is load-bearing for the tracker
#   scripts/local-checks.sh         — wired to internal CI
```
