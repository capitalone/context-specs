# Reading the probe — re-run, don't re-generate

*Hackable seam: this file controls how a reading is taken and logged. A project can adjust
the cadence and the log shape without touching the flow in SKILL.md.*

The probe (`metrics/<metric>/measure-outcome.sh`) is `/roadmap`'s artifact, synthesized
once when the metric was conceived. Your job is to **re-run it as a sensor** and record
what it reads. You do not rewrite it, tune it, or re-derive the metric — that would break
the "synthesize once, read many" contract and make readings incomparable across the
horizon (O3).

## Taking a reading

1. From the roadmap-home root, run the probe unchanged (paths are under the bet's vision):
   ```
   ./<vision-name>/metrics/<metric>/measure-outcome.sh
   ```
   It prints the current value to stdout and provenance to stderr (see `/roadmap`'s
   `probe-recipes.md`). Read **both** — confirm the number traces to a real read, exactly
   as the baseline did.
2. **If it can't read the world** (`could not connect`, `401`, empty/renamed source): the
   instrument is broken, not the metric. Stop and route it back to `/roadmap` to
   re-author the probe. Do **not** patch the probe here — a probe changed mid-measurement
   produces readings you can't compare to the baseline.
3. **If the metric's definition has genuinely changed** (the business now counts activation
   differently): that's a new conception → `/roadmap`, and effectively a new metric with a
   fresh baseline. Don't quietly redefine it inside a reading.

## Appending to `readings.log` (append-only — O6)

Add exactly one line per run, filling the provenance slot the baseline left as `-`:

```
<YYYY-MM-DDThh:mm> | <value> | bet=<bet-slug> | <repo>#<branch> @ <sha>
```

- **Line 0 is the baseline** (`… | baseline | -`) written by `/roadmap`. Never edit or
  delete it, and never edit any prior reading. The log is an immutable time-series; its
  value is that it can't be silently massaged.
- The provenance slot names the **bet** and the shipped slice that prompted the read. For a
  multi-repo bet, record the slice most responsible (or list the bet's slices in
  `bet.md` — the durable record is here in the log, by sha).
- Keep the value in the **same units** the baseline used (a percentage stays a percentage),
  or the trajectory is meaningless.

Example log across a horizon:

```
2026-06-17T09:00 | 31% | baseline | -
2026-06-21T09:00 | 33% | bet=first-value-fast | learnermax-ui#feature/onboarding-wizard @ a1b2c3
2026-06-28T09:00 | 38% | bet=first-value-fast | learnermax-ui#feature/onboarding-wizard @ a1b2c3
2026-07-05T09:00 | 37% | bet=first-value-fast | learnermax-api#feature/sample-seed @ d4e5f6
```

## Per-instrument notes

- **Instrumented (SQL / API).** Cheap and stable — re-run freely; this is the recipe that
  best supports frequent sampling. Watch for the source's own lag (a warehouse that loads
  nightly can't show today's movement).
- **Elicited (LLM-judge over artifacts).** A reading requires a **fresh set of artifacts**
  (new interviews/tickets this period) scored against the **same fixed rubric**. Growing
  the artifact set is expected; changing the rubric is a `/roadmap` redefinition (it breaks
  comparability). This recipe has real per-run cost — sample less often, deliberately.
- **Proxy.** Read as a **leading** signal: it moves first and may overstate the lagging
  truth. Note in the verdict that it's a proxy so a strong proxy reading isn't mistaken for
  confirmed retention.

## Cadence

Cadence is the human's judgment, recorded implicitly by the bet's **horizon**. Read often
enough to see a *shape* before the horizon elapses (a handful of points beats two), but the
probe's cost sets the floor — instrumented probes can be read daily, an elicited probe
maybe once or twice a horizon. The trajectory, not any single reading, is what
`trajectory-verdict.md` interprets.
