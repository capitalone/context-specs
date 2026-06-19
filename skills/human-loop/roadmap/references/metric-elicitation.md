# Metric elicitation — how to run the Q&A

*Hackable seam: this file controls the roadmap Q&A style and which measurement frameworks
it leans on. A project can rewrite it without touching the flow in SKILL.md.*

The goal is not to fill in a strategy template. It's to *sharpen* a vision until it names
an **outcome you can read**, and to refuse — gently — to let it stay a vibe. A product
person who can hand a developer a metric and a baseline knows what they want. One who
hands over a feature list and a deadline often doesn't.

## Draw the vision into a metric (R2, R3)

People open with a feature or a vision-as-slogan because it's concrete in their head:

> "We're going to make onboarding world-class."

That hides the actual outcome and prematurely fixes the *how*. Peel it back:

- **"What's broken for the user today?"** → "New signups never reach the moment the
  product is useful; most bounce before their first project."
- **"What would they *do* differently once this works?"** → "Create a first project in
  their first session instead of leaving."
- **"How would we *know* that's happening, across all users?"** → the metric: "% of
  signups who create a first project within 7 days."

Now you have an **outcome** and a **metric**, not a feature. The onboarding wizard, the
empty-state copy, the sample data — those are solutions, and they belong to `/intent`.

Useful moves:
- **"Why does that matter?"** — repeat it (the 5-whys move) until you hit the outcome the
  business actually cares about (usually retention or revenue).
- **Play it back.** "So the vision is: a new user reaches first value in their first
  session, and we'll watch activation to know. Yes?"
- **Catch features in disguise.** If the answer names a component ("a wizard", "a
  dashboard"), ask what outcome it's supposed to produce and bet on *that*.

## The throughline, in three turns (R3, R4)

For the vision, and then recursively for the metric, ask:

1. **"How would we know the vision is working?"** → forces a **metric**.
2. **"Where does that number live, and how would we read it?"** → forces an **instrument**.
3. **"What is it reading *right now*?"** → forces a **baseline** (the right-reason proof;
   see `baseline-right-reason.md`).

You are not writing strategy prose and then bolting on measurement. You are eliciting one
*readable outcome* and writing it down three ways: a line in `roadmap.md`, a hypothesis in
`bet.md`, and a line of `measure-outcome.sh`.

| You ask | They answer | → roadmap.md | → the probe |
|---|---|---|---|
| How would we know onboarding is working? | "More new users actually start using it." | metric: 7-day activation | — |
| Where does that live? | "Our events table — `project_created` keyed to `user_id`." | instrument: SQL on warehouse | `query.sql` counting activated/signups |
| What's it reading now? | "No idea." | *(don't finish until you do)* | run it → baseline 31% |

If an answer is fuzzy ("users should feel onboarded", "it should feel sticky"), keep
pushing: *"What would you look at to decide that's true?"* Either it sharpens into
something observable, or it's not a metric yet.

## The instrument taxonomy (the outcome analog of intent's check types)

Every metric reads through one of three instrument shapes. Pick the cheapest that can
actually detect movement. This mirrors how `/intent` picks deterministic / fuzzy / native
checks — and `probe-recipes.md` is the cookbook for each.

- **Instrumented** (quantitative) — a query or call against a system that already holds the
  number: a warehouse/SQL, an analytics API (PostHog, Amplitude, GA), Stripe, server logs.
  The most reliable; prefer it when the number exists somewhere. *(deterministic analog)*
- **Elicited** (qualitative) — structured human signal: user interviews scored against a
  rubric, an NPS export, coded support tickets, sales-call notes. Made rigorous by an
  **LLM-as-judge applying a fixed rubric to collected artifacts** — this is intent's
  "fuzzy" check, reused. A qualitative metric is fine; an *un-instrumented* one is not.
  ("≥3 of 5 interviews unprompted mention X" is a metric; "users will be happier" is not.)
- **Proxy** (behavioral) — a fast product-emitted event that stands in for a slow outcome
  (e.g. "reached the aha-event" as a proxy for "will retain"). Use when the real outcome is
  too slow to read inside a build cycle.

## Strategic intent — the lagging anchor (R3, R5)

A vision is anchored by a **strategic intent**: a chosen *focus area* plus the **lagging
outcome** that proves the focus is working (retention, revenue, churn — the slow metrics).
This lives in `roadmap.md`, and it's what "how would we know the *vision* is working?"
produces. One strategic intent for a focused product; up to ~three for a large org — more
is peanut-buttering. There is **no single "North Star metric"** to crown: a vision runs on
a small *portfolio* — the lagging anchor plus the leading indicators the bets move.

## Leading vs lagging — name both (R5)

The harness ships in days; retention reveals itself in weeks. So every bet names two things:

- **Leading indicator** — moves soon after ship, inside a cycle. This is what
  `/evaluate-outcome` actually watches first (activation, first-session aha, trial→paid).
  It lives on the **bet** (`bet.md`).
- **Lagging outcome** — the slow metric the leading indicator is *believed to feed*, i.e.
  the strategic intent's anchor. The roadmap tracks it, but a bet is rarely judged on it
  alone within one horizon.

Stating both makes the **hypothesis** falsifiable: "moving activation (leading) will lift
30-day retention (lagging)" is a bet you can later confirm or kill.

**Beware vanity metrics.** A number that only ever gets bigger (total signups, cumulative
pageviews) flatters without informing. Give every metric a **time component** ("7-day
activation", "30-day retention") so it can go *down* and is therefore actionable.

## The fork: new vision or new bet? (R9 — coach, never decide for them)

When a new idea arrives, help the human place it — but the call is theirs:

- **New bet** — a fresh problem under an *existing* strategic intent (same big lagging
  outcome). The common case. Lands as `bets/<bet>/` under the existing `<vision-name>/`.
- **New vision** — a *different* strategic intent: a different big lagging focus, with its
  own users/outcome. Lands as a new `<vision-name>/` folder.

The forcing question: *does this idea move an existing lagging anchor, or does it need a
new one?* If it can attach to an existing intent, it's a bet. If it genuinely needs a
different big outcome, it may be a new vision. If it can do **neither**, that's the signal
it's scope creep — not yet a bet, not yet a vision. And resist **peanut-buttering**:
spinning up a vision per idea fragments focus. Most ideas are bets. Coach toward that, then
follow their lead — `/roadmap` never auto-forks.

## Framework menus — offer, never impose

Some people think faster with a scaffold. Offer these as *menus to react against*, never as
a required form (library-agnostic principle — most products have their own metric already):

- **AARRR (Pirate)** — Acquisition, Activation, Retention, Referral, Revenue. Good for
  finding *which stage* of the funnel a vision is really about.
- **HEART** — Happiness, Engagement, Adoption, Retention, Task success. Good when the
  outcome is experiential and pulls toward an *elicited* instrument (Happiness ≈ survey).

Use them to locate the metric, then drop the framework. The deliverable is one sharp
metric with an instrument and a baseline — not a filled-in canvas.

## The decide-to-build gate (Step 3)

Stand up a roadmap **only when** you can state the vision, at least one observable metric,
and the next bet back to the human and they agree. Signs it's not ready: the vision keeps
shifting, no metric survives "how would we read it?", or every candidate metric is
unobservable. It is completely fine to end with **no artifact** — don't manufacture a
roadmap to have something to show.
