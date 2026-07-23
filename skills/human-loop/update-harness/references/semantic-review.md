# Reading a cleanly-merged skill for contradiction

`context-specs update` routes a file here when **all three versions differed, git merged
them without conflict, and the file is prose** (`*.md`).

That combination is exactly where a line-based merge is least trustworthy. git's model is
"these hunks touch different lines, so they are independent." For code that is usually
true. For a SKILL.md — a document that *instructs an agent* — it is often false: two
passages hundreds of lines apart can be jointly incoherent while being individually
clean.

The tier is deliberately broad, so **most files routed here will be fine.** Confirming
coherence in one line and moving on is the expected outcome (U8). You are looking for a
specific, small set of failures.

## Read the file whole

Not the hunks. The contradiction lives in the *relationship* between the two edits, so
you cannot see it in a diff — that is the entire reason a human-attentive skill exists
for this step.

Load the merged file, then find both changed regions (`git diff HEAD -- <path>` shows
what the update did; the report names both hunk locations).

## The failure patterns

**Contradicting imperatives.** The most common. One side adds a rule, the other rewrites
a flow that now violates it. Watch especially for `## Hard nevers` — a "never do X" added
locally while upstream rewrites a step to do X.

**Orphaned cross-references.** Skills cite each other and their own sections
(`(C8)`, `references/evals.md`, `## The guided flow`). If upstream renamed or split a
section that a local edit points at, the merge is clean and the reference is now a lie.
Check every `(U*)`/`(P*)`/`(E*)` style back-reference and every `references/` path in the
merged file still resolves.

**Duplicated guidance with different emphasis.** Both sides independently added a rule
about the same thing, in different places, with different strength ("prefer X" / "always
X"). Nothing conflicts textually; the agent reading it now gets a mixed signal.

**Step-count and ordering drift.** Upstream inserts `### Step 4`, the local edit
references "step 4" meaning the old one. Numbered flows are especially prone to this.

**Frontmatter drift.** Both sides edited `description:`. It is one line, so git may take
both fragments and produce a description that reads as gibberish or loses the `Triggers -`
tail. Always read the merged frontmatter.

## What to hand back

If coherent: one line, then move on.

If not: **quote both passages verbatim**, adjacent, so the human sees the collision
without opening the file. Then propose the reconciliation — usually a small edit to one
side, not reverting either.

> `skills/human-loop/improve-context/SKILL.md` — these two now disagree:
>
> - yours, `## Hard nevers`: "**Never run this in a worktree** — it needs the real checkout."
> - upstream, `## How to run this skill`: "Run this in a fresh worktree so the probe stays hermetic."
>
> **Recommend:** keep your never, and narrow upstream's line to the probe scripts only —
> that is the part that actually needs isolation. One sentence changed, both intents intact.
