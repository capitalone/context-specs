# The trajectory verdict — reading the shape, not a point

*Hackable seam: this file is the verdict heuristic. A project can sharpen what counts as
"moved" or "stable" for its metrics without touching the flow in SKILL.md.*

A verdict is a judgment about the **shape** of `readings.log` over the bet's **horizon**,
not a subtraction of one reading from the baseline. This is the load-bearing discipline of
the skill: a single post-ship read is rejected (O2).

## Why a single read is rejected

- **Novelty regresses.** A feature spikes on launch as existing users try it, then settles.
  The day-2 number flatters; the day-20 number is the truth.
- **The world is noisy.** Weekday/weekend swings, a campaign, a press mention, a partial
  rollout — any of these can move a single point without the bet doing anything.
- **The hypothesis is horizon-shaped.** The bet claimed a Δ *within a horizon*. You can't
  adjudicate a 2-cycle bet from one reading two days in.
- **It invites a build-trap win.** "Number ticked up, declare victory, move on" celebrates
  a delivery blip, not a sustained outcome — exactly the trap the roadmap exists to escape.

So you read **several points** and ask whether the metric *sustainably* moved.

## The four verdicts

Compare the trajectory to the bet's hypothesis (expected metric, direction/Δ, horizon):

| Verdict | Shape | Action |
|---|---|---|
| **Confirmed** | Moved decisively toward the hypothesis and **held** for a stable stretch | Record the win; the next bet builds on it. Note if a *proxy/leading* confirmed but the *lagging* North Star hasn't yet — keep watching the lagging one. |
| **Regressed** | Moved against the hypothesis, or an anti-metric/guardrail got worse | Record it; the next `/roadmap` pass pivots the hypothesis (or rolls back). A real, valuable finding. |
| **Flat** | No meaningful movement and the **horizon elapsed** | Record the null (O9). The hypothesis was likely wrong or the bet too small to register. |
| **Inconclusive / too early** | Still **within** the horizon, or moving but not yet stable | **No final verdict.** Keep sampling; name the next read date. The honest result when the evidence isn't in. |

## Movement vs noise — separating signal

- **Magnitude vs baseline variance.** If the metric historically wobbles ±3% week to week,
  a +2% reading is noise. Look for movement clearly outside the baseline's own jitter.
- **Sustained, not spiked.** Two consecutive readings holding the new level beats one high
  point. A spike that decays back is *flat*, not *confirmed*.
- **Direction over precision.** You're judging "did it move the right way and stick," not
  estimating an exact effect size. Don't over-quantify a handful of noisy points.
- **Lagging follows leading — or doesn't.** A confirmed *leading* indicator with a flat
  *lagging* North Star is a partial result: the bet changed behavior but not yet the
  outcome that behavior was supposed to feed. Say so; keep the lagging metric on watch.

## Confounders and the limits of attribution (O5)

Before calling a verdict, name what *else* could explain the trajectory this horizon — a
concurrent campaign, a seasonal effect, another bet shipping into the same metric, a
pricing change. List them in the verdict. And hold the honest line:

> The verdict is **directional, about the bet** — never proof that a specific PRD did or
> didn't work. With multiple slices and a noisy world, you cannot cleanly attribute
> movement to one change.

When attribution matters and the bet was too tangled to read, the fix is **smaller bets**
next time (cleaner cause→effect), recorded as advice for the next `/roadmap` pass — not a
more confident claim now.

## Phrasing the verdict (written into `bet.md`)

Keep it to a few lines: the verdict word, the trajectory it rests on, the confounders, and
what it implies for the next bet. Example:

```markdown
## Verdict
**Confirmed (leading).** Activation 31% → 38% over 3 weeks and held (baseline jitter ±2%);
lagging 30-day retention not yet readable this horizon — keep watching. Confounder: a
launch email went out week 1, but the gain persisted after it. Implication: the onboarding
hypothesis holds; next bet can push the same lever or move to the retention step.
```

A flat or inconclusive verdict is written the same way and is just as valuable — it's the
learning the next bet is built on (O9).
