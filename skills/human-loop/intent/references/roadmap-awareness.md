# Roadmap awareness — grounding a PRD in a roadmap, and registering it back

*Hackable seam: this file controls how `/intent` reads — and writes back to — an upstream
roadmap. A project can change how tightly a PRD couples to a bet without touching the flow in
SKILL.md.*

`/intent` slices a *problem into a feature*. Upstream, `/roadmap-init` stands up a **roadmap
home** and `/roadmap` keeps it filled: a strategy vault of **bets** (problems with a metric to
move) and a **backlog** of work (features + bugfixes) that serves them. When the user is working off a roadmap, grounding the PRD in the
relevant bet or backlog item keeps the feature pointed at an outcome someone is actually
measuring — and **registering the PRD back** ties the output you're about to build to that
outcome. This is **optional**: with no roadmap, `/intent` behaves exactly as it always has.

## The roadmap home is self-describing — defer to it

You do **not** carry the roadmap's schema. The home explains itself:

- Read the home's `AGENTS.md` once for the taxonomy and folder map.
- A **bet** lives in `<vision>/bets/<bet>/bet.md` — a problem + hypothesis + leading metric.
- A **backlog item** lives in `<vision>/backlog/{feature,bugfix}/<slug>.md` — a unit of work
  (no metric). Its conventions (frontmatter, fields, status) live in `backlog/AGENTS.md`; **read
  that for how to read and write it** — don't assume a shape here.

The home is an **Obsidian vault** (frontmatter + `[[wikilinks]]`). When you write to it, follow
those conventions — they live in the home, not in this skill.

## How to use it (Step 1.5 in the flow)

1. **Ask, don't require.** Early, ask whether this feature serves a roadmap bet or backlog
   item. If yes, have the user **pass the roadmap-home path inline** (e.g. `/intent --roadmap
   ../product-roadmap add a sample-project seeder`). There is no pointer file — the path differs
   machine to machine, so it's passed each time.
2. **Read the unit.** Read the home's `AGENTS.md`, then open the relevant `bet.md` *or* backlog
   item. Pull its **problem** (and, for a bet, the **target metric**) into your understanding of
   the *why*.
3. **Ground the PRD's `## Why`.** Write the `## Why` in the unit's terms and link back so the
   chain can trace up:
   ```markdown
   ## Why
   <the user-facing need this serves>. Serves bet **first-value-fast**
   (roadmap: ../product-roadmap) — aims to move **activation** (7-day first-project rate).
   ```
4. **Slice as usual.** A bet or feature item may need several PRDs, each with a manageable,
   runnable definition of done. File this PRD for one coherent slice; the user can `/intent` the
   next slice separately. You decide the count; the roadmap does not.
5. **Register the PRD back** (next section).

## Register the PRD back — output tied to outcome

Once the PRD branch exists, record it in the roadmap home so the bet/backlog item knows what's
being built for it. **Follow the home's `backlog/AGENTS.md` conventions** — typically: set the
backlog item's `status` (e.g. `prd-drafted`) and `prd:` pointer (`<repo>#<branch>
(prds/<feature>)`), and/or append a line to the bet's `## Slices`. Commit it in the roadmap home
(a dedicated commit if the home is its own repo); **don't auto-push** — leave that to the human.
This is the whole point of the link: a PRD the harness builds is traceable to the bet whose
indicator it's meant to move.

If you're grounding in a bet that has **no** backlog item yet, you may file the item first (per
`backlog/AGENTS.md`) and then register the PRD onto it — or just register on the bet's
`## Slices`. The home's conventions decide; when in doubt, ask the user.

## The hard line: a metric is rationale, never acceptance (P4)

A bet's metric belongs in the PRD's **`## Why`** as *rationale* — never as a criterion in
`run-prd-test.sh`.

- `run-prd-test.sh` checks **built** — deterministic, pre-merge, gated by the dispatcher
  (Invariant 8). "Does `/search` return matching posts?"
- The metric checks **moved** — lagging, measured in the world after merge, advisory, un-gated.
  "Did activation rise?"

Welding the metric into the runner would make a deterministic gate depend on a number readable
only weeks later in production. Keep the runner about observable behavior; leave the metric to
`/evaluate-outcome`. (A backlog item has no metric at all — nothing to weld.)

## What you do NOT do

- **Don't carry the roadmap's schema.** Frontmatter fields, item types, status values — all live
  in the home's `AGENTS.md`. Read them; don't hardcode them here.
- **Don't pull the whole roadmap into the PRD.** One unit's problem (+ metric, for a bet) is
  enough; the vision and candidate bets stay in the home.
- **Don't block on a roadmap.** No unit, no roadmap path, or a user who declines → proceed
  exactly as the normal flow. The roadmap is grounding, not a gate.
