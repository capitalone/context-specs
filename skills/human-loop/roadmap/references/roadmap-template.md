# Roadmap templates

Two artifacts, both lean by default. `roadmap.md` is the **vision + strategic intent** for
one vision — *not* an index (orientation lives in `AGENTS.md`; the folder tree is the map).
`bet.md` is one
**bet**. Readings never live in either — they churn in `metrics/<metric>/readings.log`, so
the strategy docs stay stable and diff-quiet.

Default to the minimal skeletons. Add an optional block **only when the conversation
surfaced it** (R10). Never emit an empty section to "be thorough."

## The home layout (per vision)

```
<home>/                             # repo root (multi-repo) OR roadmap/ folder (single-repo)
  AGENTS.md                         # static orientation — taxonomy + folder conventions (scaffolded once by /roadmap-init)
  <vision-name>/
    roadmap.md                      # this file's skeleton — vision + strategic intent + candidate bets
    bets/<bet-slug>/bet.md          # one per bet
    backlog/                        # unified work backlog — features + bugfixes (see backlog/AGENTS.md)
      AGENTS.md                     # backlog conventions (frontmatter, types) — the item schema lives here
      feature/<slug>.md             # one per feature item
      bugfix/<slug>.md              # one per bugfix item
    metrics/<metric-slug>/
      measure-outcome.sh            # the probe (see probe-recipes.md)
      query.sql | rubric.md         # what the probe reads (instrument-dependent)
      readings.log                  # append-only; line 0 is the baseline
```

This file holds the `roadmap.md` and `bet.md` skeletons. **Backlog-item shapes are not here** —
they live in the home's `backlog/AGENTS.md` and `backlog/{feature,bugfix}/AGENTS.md` (scaffolded
once by `/roadmap-init`), so the schema has one home.

## `<vision-name>/roadmap.md` (always)

```markdown
# Vision: <vision-name>

## Vision
<Where this product is going and why, in outcome terms. One short paragraph of narrative.
Not a feature list, not a metric. This is the "North Star document" in miniature.>

## Strategic intent
<The chosen focus area that realises the vision now, and why it's the priority.>
- **Lagging outcome:** `<metric-slug>` — <definition in one line>. Type: instrumented |
  elicited | proxy. Probe: `metrics/<metric-slug>/measure-outcome.sh`. Baseline: `<value>`
  @ `<date>` (see `metrics/<metric-slug>/readings.log`).
(One strategic intent for a focused product; up to ~three for a large org — more is
peanut-buttering. Each is a focus + a lagging outcome.)

## Candidate bets (problems worth betting on someday — loose and expected to churn)
- <problem worth betting on someday, named not specced>
- <another>
(Concrete work — features and bugfixes — lives in `backlog/`, not here. This list is future
*bets*, not a task list.)
```

## `bets/<bet-slug>/bet.md` (always)

```markdown
# Bet: <bet-slug>

## Problem
<The problem in user terms. Who's stuck and how. Not the solution, not a feature.>

## Hypothesis
We believe solving this moves **<leading-metric-slug>** from `<baseline>` toward `<target>`
(<direction/Δ>) within **<horizon>** (e.g. "2 release cycles", "30 days post-launch"),
which feeds the strategic intent's lagging outcome **<lagging-metric-slug>**.

## Expected value
<What we expect to gain if the hypothesis holds — in the product's own terms: $/month,
reduced churn, support load avoided. One line. Keeps the bet honest about why it's worth it.>

## Leading metric
- `<leading-metric-slug>` — <fast signal watched first>. → `metrics/<leading-metric-slug>/`
(Strongly suggested: a bet without a leading indicator can only be judged on the slow
lagging outcome, which defeats the fast measure→learn loop. Omit only with a deliberate
reason — e.g. a proxy is the only readable signal.)

## Target repos
- <repo where a slice will likely land> — <why>
- (one entry for a single-repo product; several for a multi-repo bet)

## Slices (registered by /intent as it files PRDs against this bet's backlog items)
- <repo>#<branch> (`prds/<feature>`) — <status>
- (left empty at roadmap time; `/intent` appends a pointer when it files a PRD; a Dataview
  rollup over `backlog/` `bet:` frontmatter is the fuller view)

## Status
shipping        # shipping → evaluate-ready (live end-to-end) → evaluated

## Verdict (written by /evaluate-outcome)
<empty until the bet is evaluated>
```

## Optional blocks (add only when raised)

```markdown
## Anti-metric / guardrail            # in roadmap.md or bet.md
- <a number that must NOT get worse while we chase the target — e.g. "p95 latency stays
  < 400ms", "refund rate doesn't rise">. Keeps a bet from winning the metric by breaking
  something else.

## Confounders                        # in bet.md
- <known external thing that could move the metric independently this horizon — a holiday,
  a concurrent campaign — so /evaluate-outcome reads the trajectory with eyes open>
```

## Notes
- **Bets are problems, not features** (R2). If a bet names a component, restate it as the
  outcome the component would produce.
- **roadmap.md is strategy, not navigation.** It holds the vision, the intent + lagging
  anchor, and a loose list of *candidate bets*. There is no maintained index anywhere — the
  folder structure is the map, and `AGENTS.md` (written once) explains what the folders mean.
- **Metrics point to their probe + log; never inline readings.** The time-series lives in
  `readings.log` so the strategy docs stay stable.
- **Slice pointers are registered by `/intent`.** When it files a PRD against a backlog item,
  `/intent` appends the pointer (here and on the item) — output tied back to outcome.
- **Horizon is mandatory** on a bet — without it, "did it move?" has no clock and a single
  early read masquerades as a verdict.
