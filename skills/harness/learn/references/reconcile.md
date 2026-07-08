# Reconcile — the new write logic

**Hackable seam.** How `/learn` decides what to **add, edit, and delete** in the
Expert. Replaces the old consensus pass: reasoning happens inline in the main
agent (no subagent fanout), but every proposed change carries a one-line
justification cited from the diff or the contradicting reference file.

## The premise

Memory's *facts* must reflect what is true on main right now — not what was true
at the last merge plus everything observed since. Memory's *direction*
(developer-written decisions and aspirations) must reflect current intent.
Reconcile both. So every `/learn` run does three things, in order:

1. **Add** facts that appear in the merged diff and aren't in the Expert yet.
2. **Edit** existing reference files whose claims are still relevant but
   incomplete or outdated.
3. **Delete** reference files whose underlying concept no longer exists in code,
   or that contradict a more recent file beyond rescue.

## The three reconcile passes

Run these in order, in the main agent (no subagents). Each produces entries on
one of three candidate lists: `adds[]`, `edits[]`, `deletes[]`. Every entry
carries a **one-line justification** citing either a specific diff hunk
(file:line range) or a specific contradicting reference file. If you can't write
the justification, drop the candidate

### Pass 1 — Deleted-concept pass

For each `concept-*.md` and `how-to-*.md` in the Expert:

1. Extract the file's **key code references**: paths it mentions, function or
   class names, module identifiers, command names.
2. For each, check whether it still exists post-merge: `git cat-file -e
   <sha>:<path>`, `git grep -E <identifier>`, or equivalent.
3. Decide:
   - **Wholly gone** (no references survive) → mark **delete**.
   - **Partially gone** (some references survive, some don't) → mark **edit**;
     prune the dead pointers and update the prose.
   - **All present** → no action from this pass.

Do the same for `invariant-*.md` and `pattern-*.md`: if the rule's anchor code
is gone (the layer, the module, the API surface), the rule is dead.

**Skip `decision-*` shards in this pass — mechanically, by prefix.** A
`decision-*` file is forward-looking direction; it has no anchor code *by design*,
so "the anchor is gone" is never a delete signal for it. Do **not** run the code
existence check on `decision-*` files. Instead, ask only two questions of each,
both keyed on the merged diff:

- Did this merge **fulfill** the decision (the code now matches the direction it
  stated)? → **promote and retire**: fold the now-true content into the matching
  `concept-*`/`pattern-*` shard (`add`/`edit`), then `delete` the `decision-*`
  file. Justification cites the realizing diff hunk.
- Did this merge **reverse** it (a change that abandons the direction, or a
  human-authored edit in this diff that supersedes it per P7)? → `edit` or
  `delete`, following the human if they acted.

If the merge does neither, leave the decision **untouched** — you never seed,
rewrite, or delete a live decision on your own initiative. (Fact shards —
`concept-`/`how-to-`/`invariant-`/`pattern-` — still get Pass 1's normal
anchor-existence treatment above.)

### Pass 2 — Inter-file contradiction pass

Build a list of **topic-related file pairs**:

- Pairs that share a wikilink (one references `[[the-other]]`).
- Pairs whose slugs share two or more tokens (e.g. `pattern-error-handling.md`
  and `how-to-handle-errors.md`).
- Pairs that mention the same code paths or identifiers.

For each pair, read both files in full and ask: **do they assert opposing
facts?** Common patterns:

- **Stale + Fresh.** One was written before a refactor; the other after.
  Resolution: drop the stale file (`delete`); the fresh one already covers the
  current truth. Justification cites the merge sha that made the older claim
  false.

- **Two facets of one rule.** Two files about the same underlying concept that
  disagree because they were each scoped narrowly. Resolution: **merge them**
  into one file (`add` the merged file, `delete` both originals). Update any
  inbound wikilinks. Justification names both prior files.

- **Both true at different scopes.** Each is correct in its own context.
  Resolution: `edit` both to scope-qualify ("inside the repo layer, …"; "at the
  service boundary, …"). Justification cites the scope distinction.

**Default heuristic: rewrite both / scope-qualify.** Drop one only when one is
clearly stale (its anchor code is gone, it predates a refactor that already
landed, or a human-authored P7 edit in this diff supersedes it). A `decision-*`
shard and a fact shard (`pattern-`/`concept-`) that "disagree" are **not** a
contradiction — they're a now/next pair: the fact describes today, the decision
describes where the project is going. Leave both; never delete a decision here
(its only retirement path is fulfil/reverse in Pass 1). Never silently delete on
contradiction — every `delete` shows up in the PR body with its one-line
justification.

### Pass 3 — Diff-invalidates-file pass

For each code path touched by the merged diff, scan all references that mention
that path. For each reference:

- Does the merge **contradict** a claim in the file? → mark **edit**.
- Does the merge **extend** a claim (new module added, new step in a how-to)?
  → mark **edit** to incorporate, or **add** a new sibling file if the new
  topic deserves its own.
- Does the merge **replace** the concept the file is about? → see Pass 1 (may
  become a `delete`).

## Routing and writing

After reconcile, each entry on `adds[]` / `edits[]` / `deletes[]` is routed
through `routing-rules.md` to pick its prefix (`how-to-*` / `concept-*` /
`pattern-*` / `invariant-*` / `example-*`) or — for an `add` — to be redirected
to AGENTS.md, a lint, or nowhere instead. (`decision-*` is not in this list on
purpose: you never *add* a decision — it's human-authored direction. Your only
`decision-*` writes are the fulfil-promotion and reverse-delete from Pass 1.)

Write logic:

- **Add** → create the file, add it to `SKILL.md`'s index, populate wikilinks to
  related references.
- **Edit** → rewrite the relevant section. If a wikilink target was renamed or
  deleted, fix the inbound link.
- **Delete** → `rm` the file, remove its row from `SKILL.md`'s index, and
  rewrite any inbound wikilinks (drop them or repoint).

`check-expert-links.sh` will fail the PR if any inbound wikilink was missed.
That's the safety net.

## Nothing to learn

If after all three passes plus routing the candidate sets are empty:

```
len(adds) + len(edits) + len(deletes) == 0
AND no candidate AGENTS.md pointer change
AND no candidate lint
```

…then `/learn` prints:

```
learn: nothing to learn from <sha>, skipping PR
```

…to stdout, exits 0, and does **not** push a branch or open a PR. This is a
valid, common outcome — most merges are routine and produce nothing for memory.
The harness's outer loop advances `refs/harness/last-learned` regardless of
whether a PR opened, so the watermark keeps moving forward.

## Why no subagent consensus

The old design ran 2–3 cheap reviewers and required a 2/3 vote. That gated
hallucinations, but at the cost of a fanout step and the parallel review
overhead. The inline justification rule does the same job more cheaply: the
single agent must cite the diff hunk or contradicting file for *every*
candidate. Anything without a citation is dropped. A `--dry-run` flag (for
human-driven evaluation) prints the candidate set with justifications and
opens no PR — useful when a project wants periodic spot-checks on how `/learn`
is reasoning.
