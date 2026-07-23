# AGENTS.md guidance — map, not encyclopedia

**Hackable seam.** AGENTS.md is the project's *eager* memory: loaded automatically
as an agent traverses the repo (root first, then nested files closer to the working
directory override/extend). It is vendor-neutral (the open equivalent of a
tool-specific memory file) — which is also why this design uses it instead of a
proprietary file: your memory stays portable and yours.

## The one rule: it's a table of contents

AGENTS.md **points into** the Expert and the code; it does not hold the knowledge.
The failure mode (well documented) of a big AGENTS.md:

- Context is scarce — a giant file crowds out the task and the code.
- When everything is "important," nothing is — the agent stops navigating.
- It rots instantly and is hard to verify.

So the root file is a ~map: onboarding pointers, the consult-the-Expert rule, the
branch lifecycle, the non-bypassables. Pointer-shaped lines, not paragraphs.

## Which folders earn a nested AGENTS.md

Default to **fewer files**. A folder earns its own AGENTS.md only when the work
that lands there has a **folder-local rule** that clears all five predicates in
`routing-rules.md` — something an agent editing files *in that folder* must know
and cannot infer from the code. Otherwise, update the root map's pointer instead.

When a merge introduces such a rule and no nested file exists, propose creating one
(in the same `learn/<sha>` PR). Keep it ≤ 80 lines. Don't repeat anything the root
already says — nested files inherit.

## Freshness is enforced, not hoped for

Because AGENTS.md rots, `scripts/check-agents-md.sh` mechanically validates: every
path it references exists, cross-links resolve, and it's under the line cap. Wire
this into `local-checks.sh`/CI so a stale pointer fails the build. This is the same
"enforce invariants mechanically" instinct turned on the memory files themselves.

> AGENTS.md uses regular `[text](path)` markdown links — **not** wikilinks. The
> Obsidian-style `[[wikilinks]]` convention is internal to `expert/references/`
> only; it has its own validator (`check-expert-links.sh`). Keep the two link
> styles separate so each validator stays simple.

## Caps (tweakable, enforced by check-agents-md.sh)
- Root: ≤ 150 lines.
- Nested: ≤ 80 lines.
