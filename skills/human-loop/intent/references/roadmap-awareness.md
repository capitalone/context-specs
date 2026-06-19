# Roadmap awareness — grounding a PRD in a bet

*Hackable seam: this file controls how `/intent` reads an upstream roadmap. A project can
change how tightly a PRD couples to a bet without touching the flow in SKILL.md.*

`/intent` slices a *problem into a feature*. Upstream, `/roadmap` slices a *vision into
problems* — each problem is a **bet**, tied to an outcome **metric**. When the user is
working off a roadmap, reading the relevant bet sharpens the PRD's `## Why` and keeps the
feature pointed at an outcome someone is actually measuring. This is **optional**: with no
roadmap, `/intent` behaves exactly as it always has.

## What a bet is (the altitude above a PRD)

A bet lives in a **roadmap home** (a separate repo for a multi-repo product, or a
`roadmap/` folder for a single-repo one), organized per vision:

```
<home>/
  AGENTS.md                          # static orientation — explains the folder taxonomy
  <vision-name>/
    roadmap.md                       # vision + strategic intent + lagging outcome
    bets/<bet-slug>/bet.md           # one problem, as an outcome hypothesis
    metrics/<metric-slug>/...         # the probe that measures the metric (NOT your concern)
```

`AGENTS.md` explains the folder taxonomy (read it once); the **folder structure is the
map** — browse `<vision-name>/bets/` to find the bet. `bets/<bet-slug>/bet.md`
holds: the **problem** (in user terms), a **hypothesis** (leading metric + expected Δ +
horizon), the **expected value**, and **target repos**. A bet decomposes into **one or many
PRDs** — the slicing you're about to do. The metric lives on the **bet**, and exactly one
`/evaluate-outcome` runs at the bet level once it ships; it is **not** your job and **not**
part of any PRD.

## How to use it (Step 1.5 in the flow)

1. **Ask, don't require.** Early in the conversation, ask whether the user has a roadmap bet
   they're working toward. If yes, have them **pass the roadmap-home path inline** (e.g.
   `/intent --roadmap ../product-roadmap add a sample-project seeder`). There is **no
   pointer file** — `/intent` only reads the roadmap, and read-only access has no reason to
   persist a path that differs machine to machine.
2. **Read the bet.** Read `AGENTS.md` for the conventions, then browse `<vision-name>/bets/`
   to find the bet and open `<vision-name>/bets/<bet-slug>/bet.md`. Pull the **problem** and
   the **target metric** into your understanding of the *why*.
3. **Ground the PRD's `## Why`.** Write the PRD's `## Why` in the bet's terms — the problem
   it serves and the metric it's meant to feed — and reference the bet so the chain can
   trace up:
   ```markdown
   ## Why
   <the user-facing need this feature serves>. Part of bet **first-value-fast**
   (roadmap: ../product-roadmap) — aims to move **activation** (7-day first-project rate).
   ```
4. **Slice as usual.** A bet may need several PRDs to each have a manageable, runnable
   definition of done. Slice it the way you normally would — file this PRD for one coherent
   slice, and the user can `/intent` the next slice separately. You decide the count; the
   roadmap does not.

## The hard line: metric is rationale, never acceptance (P4)

The bet's metric belongs in the PRD's **`## Why`** as *rationale* — so the builder knows
the point of the work. It must **never** become a criterion in `run-prd-test.sh`.

- `run-prd-test.sh` checks **built** — deterministic, pre-merge, gated by the dispatcher
  (Invariant 8). "Does `/search` return matching posts?"
- The metric checks **moved** — lagging, measured in the world after merge, advisory,
  un-gated. "Did activation rise?"

Welding the metric into the runner would make a deterministic gate depend on a number that
can only be read weeks later in production — it would never pass at build time, and it
would break the clean altitude line. Keep the runner about observable behavior; leave the
metric to `/evaluate-outcome`.

## What you do NOT do

- **Don't write to the roadmap home.** `/intent` only reads it. The bet's **slice
  pointers** (which PRD/branch serves the bet) are **human-maintained** — there are many
  valid ways to attribute a PRD to a bet, and it's out of scope for this skill. You may
  *remind* the user they can record this slice in `bet.md`, but you don't commit it.
- **Don't pull the whole roadmap into the PRD.** One bet's problem + metric is enough; the
  vision and backlog stay in the roadmap home.
- **Don't block on a roadmap.** No bet, no roadmap path, or a user who declines → proceed
  exactly as the normal flow. The roadmap is grounding, not a gate.
