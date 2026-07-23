# Routing rules — the four destinations

**Hackable seam.** This file *is* the judicial bar. A project edits the predicates
and the caps to its taste; the flow doesn't change.

Every fact worth remembering routes to **exactly one** destination. Most facts go
to the last two rows.

| Destination | Use when | Cost model |
|---|---|---|
| **A lint** (`scripts/lints/*` → `local-checks.sh`) | The rule is *mechanically checkable* — pass/fail needs no judgment (layer-dependency direction, "parse at boundaries", naming, no raw SQL interpolation, structured-logging-only, file-size caps) | Best: enforced on every PR forever, and the failure message doubles as a fix prompt. See `invariant-discovery.md`. |
| **Eager prose** (`AGENTS.md`) | It clears **all five predicates** below | Paid in tokens on *every* session that touches the folder — strict bar. |
| **Lazy prose** (an Expert reference file) | Useful when an agent is *deliberately reasoning* about this area, but not needed pre-emptively | Paid only when consulted — looser bar. The default home for real knowledge. Splits into six sub-destinations (see below). |
| **Nowhere** | Inferable from the code, taste-only, or transient | — |

## Sub-routing for lazy prose: the six prefixes

A fact destined for the Expert lands in exactly one prefixed file. See
`expert-structure.md` for the directory layout.

| Sub-destination | Use when |
|---|---|
| `how-to-<verb-noun>.md` | Procedural SOP — a sequence of steps. Imperative voice. "How do I X?" |
| `concept-<topic>.md` | Semantic — a noun, a model, the shape of the system. "What is X?" |
| `pattern-<topic>.md` | Soft DO/DON'T requiring judgment. Has counterexamples. Cannot be linted. |
| `invariant-<rule>.md` | A single hard rule, mechanically checkable in principle. One rule per file; filename = the rule. The highest-value ones get drafted as lints. |
| `example-<scenario>.md` | Episodic / few-shot — a *past* concrete trace (PR, merge, debugging session) cited from a real sha. Never synthetic. |
| `decision-<slug>.md` | A forward-looking choice not yet realized in code (direction, migration, convention for new work). Carries an *Until fulfilled* note. Human-authored; `/learn` never seeds one. |

**Tiebreakers:**

- A step list → `how-to`. A noun or definition → `concept`. A rule → `invariant`
  if linable, else `pattern`. A past trace with a sha → `example`.
- Code **already follows it** → `pattern`. A **target the code hasn't reached
  yet** → `decision`.
- If a fact is *both* procedural and load-bearing as a rule, write both: the
  `how-to-*` mentions the rule and wikilinks `[[invariant-*]]`.
- One rule per `invariant-*.md` file — never bundle multiple invariants.

## The five-predicate test for *eager* (AGENTS.md) placement

A fact earns a line in AGENTS.md only if **all five** hold. If any fails, it goes
to the Expert (lazy) or nowhere.

1. **Needed before consultation** — an agent will hit the relevant code *before it
   would think to open the Expert*. (Pre-emptive, not on-demand.)
2. **Non-inferable** — it can't be read off the local code; it's tribal/contextual.
3. **Harm on violation** — breaking it breaks behavior, leaks data, or regresses.
   Not style, not taste.
4. **Stable** — it won't rot next week.
5. **Local (or truly global)** — for a nested AGENTS.md, the rule is specific to
   that folder; for the root, it's genuinely repo-wide.

## Why the bar differs

The Expert is *pulled on demand* — progressive disclosure. AGENTS.md is *eager* —
the agent reads it automatically as it enters a folder, before knowing if it's
relevant. So every AGENTS.md line is a standing tax; every Expert line is paid only
when it earns its keep. **When in doubt, prefer the Expert over AGENTS.md, and
prefer nothing over noise.**

## Line-count caps (tweakable)

- Root `AGENTS.md`: **≤ 150 lines.** Beyond ~150, research shows diminishing
  returns and rising inference cost with no quality gain.
- Nested `AGENTS.md`: **≤ 80 lines.**
- `scripts/check-agents-md.sh` enforces these mechanically.

## The map/territory rule

AGENTS.md **points into** the Expert; it never copies it. A pointer ("this folder
does X; consult `expert/references/Y.md` before non-trivial work") stays correct as
the Expert grows. A copied paragraph drifts. Reference, don't duplicate.

## Deletes — routing the other direction

Routing rules also decide when an existing reference file should be **removed**.
A `delete` candidate is justified when one of these holds:

- **Deleted concept.** The code the file anchors to is gone from main — the
  module, route, command, or identifier it cites no longer exists. (See pass 1
  in `reconcile.md`.)
- **Superseded by a fresher file.** Two reference files contradict, and one is
  clearly stale (its anchor code is gone, or a more recent merge supersedes its
  claim). The stale one is deleted. (See pass 2 in `reconcile.md`.)
- **Merged into another.** Two files covered overlapping topics and have been
  combined; the originals are deleted in favor of the merged file.

Every `delete` carries a one-line justification in the PR body. Inbound
wikilinks must be rewritten or removed in the same PR;
`scripts/check-expert-links.sh` fails the build if any inbound link still
points at a deleted target.

None of these triggers apply to a **`decision-*` shard** (forward-looking
direction not yet in code) — its delete trigger is a merge that **fulfills** it
(promote to a `concept-`/`pattern-` fact, then delete) or a decision that's been
**reversed**, never a missing code anchor. See the decision handling in
`reconcile.md`.
