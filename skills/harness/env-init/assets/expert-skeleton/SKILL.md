---
name: expert
description: This project's long-term memory — how to run, validate, and extend it; its architecture, patterns, hard invariants, worked examples, and current decisions/direction. Consult when planning a feature, validating a spec, implementing a slice, or writing intent for this project. Routing table below points to one small reference file per topic.
---

# The Expert — this project's long-term memory

<!--
  YOU (the developer) OWN THIS MEMORY.

  Two continuous helpers file things into it — /learn after every merge, and
  the implementer's Reflect step after every slice — but editing it directly
  is expected, not exceptional. Update it rapidly and constantly — decisions
  and direction included; don't wait for code to land. This memory informs
  every future feature's plan: improving it is the highest-leverage work you
  can do on this project. If a spec plan uses the wrong abstraction or misses
  a convention, the fix belongs HERE, in the shard that should have taught it.
-->

## How to use this memory

Scan the routing table, open **only** the reference files whose `USE WHEN` matches
the task at hand. Each file is one topic; files cross-link with `[[wikilinks]]`
(resolve `[[name]]` to `references/name.md`). Do not page through everything.

## Facts vs. decisions

Most shards describe the code as it IS — plan and build consistently with them. A
`decision-` shard describes where the project is HEADING; the code may not reflect
it yet.

When your task touches an area a decision covers, make a call: does this work
**advance** the decision (build the new way) or stay **consistent with current
code** (build the old way)? Read the decision's "Until fulfilled" note first — it
answers this for its case. If it's silent: new isolated code follows the decision;
changes to existing code stay consistent with what surrounds them, unless the task
*is* the migration. Never assume a decision is already implemented — verify the
current state in code before planning against it.

## Routing table

<!-- One line per reference file. Keep this in sync — a file not listed here is
     invisible. Prefixes: how-to- (procedural SOP) · concept- (what is X) ·
     pattern- (soft DO/DON'T, judgment) · invariant- (one hard rule per file) ·
     example- (episodic, cited from a real sha) · decision- (forward-looking
     direction not yet in code). -->

| Reference | USE WHEN |
|---|---|
| _(empty — the first /learn, Reflect, or your own edit adds the first shard)_ | |

## Writing to this memory

- **One topic per file**, named `<prefix>-<topic>.md`, opening with a `USE WHEN:` line.
- **Anything that helps the next agent belongs here** — facts about the code as it
  is (cite file paths, shas) AND decisions, direction, and aspirations about where
  it's going. Make clear in the prose which is which.
- **Facts** → `how-to-`/`concept-`/`pattern-`/`invariant-`/`example-`, cited.
  **Direction** (a choice the code hasn't caught up to) → `decision-<slug>.md`:
  the direction and why, a `[[concept-…]]` pointer to the current state, and an
  **Until fulfilled:** note (what advances the decision vs. what stays consistent
  with today's code). No status field — the file existing means it's adopted.
- **Reconcile, don't accumulate** — when reality *or intent* changes, edit or delete
  the shard. A merge that fulfills a decision promotes it to a `concept-`/`pattern-`
  fact and deletes the decision; a decision you've walked back gets deleted, not
  appended to.
- Add the routing-table line in the same commit as the shard.
