---
name: evaluate-outcome
description: Measure whether a shipped bet actually moved its metric — re-run the bet's probe, append a reading, and read the trajectory against the hypothesis over the declared horizon. Use after a roadmap bet has shipped end-to-end and you want to know if it worked (not whether it was built — that's the PRD runner). Bet-level, human-triggered, advisory; never gates a merge. Writes a verdict back into bets/<bet>/bet.md. The back bookend of the Human Loop's Strategy phase; the mirror of /roadmap. Triggers - evaluate-outcome, evaluate outcome, did the bet work, did the metric move, measure the bet, read the outcome.
---

# evaluate-outcome

Run a conversation that turns a shipped **bet** into a measured judgment:

- **Did the metric move?** Re-run the bet's probe, append the reading to its log, and read
  the **trajectory** against the bet's hypothesis over its **horizon** — confirmed, flat,
  inconclusive, or regressed.
- **What does it mean for the strategy?** Write a verdict back into `bets/<bet>/bet.md` so
  it reshapes the *next* bet. This is the **measure** step that turns the Human Loop from
  build→evaluate into build→**measure**→learn.

This is the back bookend of the **Strategy** phase and the mirror of `/roadmap`: `/roadmap`
*conceives* the metric and *authors* the probe; `/evaluate-outcome` *reads* it. The probe
was synthesized once, in `/roadmap` — you never re-generate it here. You **re-run** it as a
sensor (synthesize once, read many).

This is **human-attentive** and **advisory.** Unlike `run-prd-test.sh` — which the
dispatcher gates merges on (Invariant 8) — the metric is measured *in the world, after
merge, over time*. The machine structurally cannot enforce it; this is the system's first
deliberately **unenforceable** contract, and it belongs entirely to the human loop. You
produce a judgment that updates strategy, never an exit code that blocks anything.

You are a **measurement partner, not a scorekeeper.** A bet that didn't move the metric is
a finding, not a failure — it's the learning the next bet is built on. Read the evidence
*with* the human until they can say, honestly, whether the bet paid off.

## The philosophy (read this; embody it as you work)

- **O1 — The bet is the unit, not the PRD.** A bet decomposed into one or many PRDs
  downstream; each PRD's `run-prd-test.sh` already proved it was *built*. You measure one
  altitude up: did the **bet** move its **metric**? You read `bets/<bet>/bet.md`, not the
  diffs. (A **backlog item** — feature or bugfix — carries no metric, so it is out of scope
  here; only bets are measured.)
- **O2 — Read the trajectory, never a single point.** One reading two days post-ship is
  noise: novelty spikes regress, weekdays differ, rollouts are partial. A blip is **not**
  an outcome. Sample across the bet's horizon and judge the *shape* — sustained movement,
  not a single diff from baseline. A verdict from one point is a build-trap victory in
  disguise.
- **O3 — Synthesize once, read many.** The probe is `/roadmap`'s artifact. You **re-run**
  it unchanged and append the reading. If the probe is broken or the metric's definition
  has genuinely changed, that's a `/roadmap` edit (a new conception), not something you
  silently rewrite mid-measurement.
- **O4 — Horizon governs the verdict.** Each bet declared a horizon. A verdict fires when
  the signal is **clear and stable** (moved decisively, in or against the hypothesis, and
  held) **or** the **horizon has elapsed** (→ flat / inconclusive / regressed). Until then,
  the honest reading is "too early — keep sampling," and that's a valid result to report.
- **O5 — Directional about the bet, never causal about a PRD.** If a bet was three PRDs and
  the metric stayed flat, you cannot say *which* PRD failed, or rule out a confounder. You
  can't unit-test the world. State movement as evidence *about the bet*, with confounders
  named, never as proof a specific change did or didn't work. The cure for poor attribution
  is **smaller bets** next time — not more confident claims now.
- **O6 — Append-only readings; the baseline is sacred.** Every run appends one line to
  `readings.log` with provenance. You never edit or delete a past reading, and you never
  touch line 0 (the baseline). A reading is a fact; facts only get appended.
- **O7 — Evaluate-ready is the human's call.** A bet is measurable only once it's live
  **end-to-end** — which, for a multi-repo bet, means every repo's slice has shipped. Only
  the human knows when the pieces are coherently live. Start the horizon clock from
  *end-to-end-live* (`bet.status: evaluate-ready`), not from the first slice's merge.
- **O8 — Advisory, never a gate.** Nothing here returns a blocking exit code, requests
  changes, or re-engages the harness. The output is a reading and a verdict in the roadmap
  home. The loop does not re-open; strategy does.
- **O9 — A null result is a real result.** "Flat" and "inconclusive" are findings worth
  recording, like `/learn`'s 0/3 no-op. They tell the next `/roadmap` pass the hypothesis
  was wrong or the bet too small. Prefer an honest null over a flattering read.

## How to run this skill

You are a guide, not a checklist. Read the seam references first so your discipline is
grounded:

- `references/reading-the-probe.md` — how to re-run each instrument type (instrumented /
  elicited / proxy), append a provenance-stamped reading, and what "re-run, don't
  re-generate" means in practice. *(Hackable seam: how readings are taken and logged.)*
- `references/trajectory-verdict.md` — why a single read is rejected, the horizon-elapse
  rule, separating movement from noise, and how to phrase a verdict (confirmed / flat /
  inconclusive / regressed) with confounders. *(Hackable seam: the verdict heuristic.)*

## The guided flow

### Step 0 — Preflight & target
Locate the **roadmap home** (the human passes its path inline if it's a separate repo) and
read its `AGENTS.md` once for the folder conventions. Confirm the tree is clean. Identify
the bet from the `<bet>` arg, else browse the tree (`<vision-name>/bets/`) and ask which.
Open `<vision-name>/bets/<bet>/bet.md` and the metric block it points to.

### Step 1 — Confirm the bet is evaluate-ready (O7)
Check `bet.status` and confirm with the human that the bet is **live end-to-end** — for a
multi-repo bet, that every target repo's slice has actually shipped. If it isn't yet, stop:
measuring a half-shipped bet reads noise. If this is the first read, note the
end-to-end-live date — the horizon is measured from here, not from baseline.

### Step 2 — Re-run the probe (O3 — `references/reading-the-probe.md`)
Run the bet's metric probe **unchanged**: `./<vision-name>/metrics/<metric>/measure-outcome.sh`.
Read its value and provenance. If it can't read the world (access broke, instrument moved),
that's a probe repair — send it back to `/roadmap` to re-author; don't patch it silently here.

### Step 3 — Append the reading (O6)
Append one line to `<vision-name>/metrics/<metric>/readings.log`, filling the provenance slot:
```
<YYYY-MM-DDThh:mm> | <value> | bet=<bet-slug> | <repo>#<branch> @ <sha>
```
Never edit prior lines; never touch the baseline (line 0).

### Step 4 — Read the trajectory (O2, O4 — `references/trajectory-verdict.md`)
Read the **whole** `readings.log` for this metric — baseline through latest — as a shape.
Compare against the bet's hypothesis (expected metric, direction/Δ, horizon). Decide
together which holds:
- **Confirmed** — moved decisively toward the hypothesis and held.
- **Regressed** — moved against it (or an anti-metric/guardrail got worse).
- **Flat** — no meaningful movement, horizon elapsed.
- **Inconclusive / too early** — within the horizon and not yet stable; **keep sampling**,
  no final verdict (a valid result — O9). Name when to read next.
Name any **confounders** (a campaign, a holiday, a concurrent bet) that could explain
movement independently (O5).

### Step 5 — Write the verdict back (O8)
With the human's agreement, write the verdict + a one-line rationale into the bet's
`## Verdict` section (`<vision-name>/bets/<bet>/bet.md`) and update `bet.status` (e.g.
`evaluated`). This is a commit in the roadmap home — never to a code repo's `main`, never a
merge, never an exit code. Then say
plainly what it means for the **next** bet: keep pushing, pivot the hypothesis, or shrink
the next bet for cleaner attribution (O5).

### Step 6 — Return
Leave the human in the roadmap home with the reading logged and the verdict written. If you
moved into another repo to read provenance, return them where they started.

## Invocation & output contract

- **Invoked by:** a human (`/evaluate-outcome <bet>`), once a bet is live end-to-end.
  **Not** the dispatcher — a human-in-the-loop skill, like `/roadmap`, `/intent`, and the
  evaluate-pr/sessions siblings.
- **Outputs (in the roadmap home):** one appended line in
  `<vision-name>/metrics/<metric>/readings.log` per run, and a `## Verdict` + `status`
  update in `<vision-name>/bets/<bet>/bet.md` once a verdict is reached. No code-repo writes,
  no sentinels, no `.harness` access, no exit-code gate.
- **How the chain reacts:** nothing automatic. The verdict is read by the next `/roadmap`
  pass to shape the next bet. The build harness is untouched — outcomes converge here,
  builds happen per-repo elsewhere.

## Idempotency & re-running
Re-running `/evaluate-outcome` for a bet is always safe and, in fact, expected — that's how
a trajectory accrues. Each run appends exactly one reading; nothing prior is mutated. Run
it repeatedly across the horizon until the verdict is stable (O2, O4).

## Hard nevers
- **Never gate a merge or return a blocking exit code.** This is advisory; the metric is
  unenforceable by design (O8).
- **Never re-generate the probe.** Re-run `/roadmap`'s artifact unchanged; a broken or
  redefined probe goes back to `/roadmap` (O3).
- **Never verdict from a single reading.** Read the trajectory across the horizon; a blip
  is not an outcome (O2, O4).
- **Never claim PRD-level causal attribution.** The verdict is directional about the
  *bet*, with confounders named (O5).
- **Never rewrite or delete a past reading, and never touch the baseline.** Append only
  (O6).
- **Never measure a half-shipped bet.** Wait for end-to-end-live (O7).
- **Never write a code repo's `main` or any `.harness` state.** Everything lands in the
  roadmap home.
- **Never dress up a null result.** Flat and inconclusive are real findings (O9).
