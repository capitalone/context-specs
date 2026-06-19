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
  AGENTS.md                         # static orientation — taxonomy + folder conventions (assets/AGENTS.md.template)
  <vision-name>/
    roadmap.md                      # this file's skeleton — vision + strategic intent + backlog
    bets/<bet-slug>/bet.md          # one per bet
    metrics/<metric-slug>/
      measure-outcome.sh            # the probe (see probe-recipes.md)
      query.sql | rubric.md         # what the probe reads (instrument-dependent)
      readings.log                  # append-only; line 0 is the baseline
```

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

## Backlog (problems, not features — loose and expected to churn)
- <problem worth betting on someday, named not specced>
- <another>
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

## Slices (human-maintained — filled in as /intent files PRDs)
- <repo>#<branch> (`prds/<feature>`) — <status>
- (left empty at roadmap time; updated by hand as work ships — out of skill scope to sync)

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
  anchor, and a loose backlog. There is no maintained index anywhere — the folder structure
  is the map, and `AGENTS.md` (written once) explains what the folders mean.
- **Metrics point to their probe + log; never inline readings.** The time-series lives in
  `readings.log` so the strategy docs stay stable.
- **Slice pointers are human-maintained.** `/intent` does not write them.
- **Horizon is mandatory** on a bet — without it, "did it move?" has no clock and a single
  early read masquerades as a verdict.
