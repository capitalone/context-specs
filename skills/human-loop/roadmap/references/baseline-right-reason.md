# The baseline read — the right-reason proof

*Hackable seam: this file is the roadmap's "right-reason heuristic." A project can sharpen
what counts as a valid baseline for its instruments without touching the flow in SKILL.md.*

This is the load-bearing check that proves the metric is **real**, the mirror of
`/intent`'s "failing for the right reason" (its `references/right-reason.md`). After
drafting the probe, you run it **against the live world right now** and inspect *what it
returns*.

`/intent` runs its runner against *unbuilt* code and expects a **red** that exercises the
missing behavior. `/roadmap` runs its probe against the *live world* and expects a
**current reading** that the instrument can actually produce. Same act — run the artifact
at birth to prove it corresponds to reality — opposite expected result (a number, not a
failure).

A probe that returns a number is necessary but not sufficient. It must return a number
**because the instrument genuinely reads the metric** — not because it printed a constant,
hit the wrong table, or silently swallowed an error.

## Right reason vs wrong reason

| What the probe does | Why | Verdict |
|---|---|---|
| SQL returns `31%` from `project_created` / `signups` | The instrument reads the real metric | ✅ Right reason — this is the baseline |
| Analytics API returns the activation funnel value | Reads the live number | ✅ Right reason |
| Interview rubric scored over 5 real transcripts → `2/5` | Elicited metric, instrument exists and was applied | ✅ Right reason |
| Prints `0%` because the events table is empty / wrong name | Instrument is mis-wired, not reading the metric | ❌ Wrong reason — fix the query |
| `psql: could not connect` / `401 Unauthorized` | No access to the source | ❌ Wrong reason — fix access (pointer/creds) before finishing |
| Returns a hardcoded `50%` placeholder | Probe doesn't actually read anything | ❌ Wrong reason — wire it to the source |
| "We'll interview users *later*" | No artifacts to judge yet | ❌ Not a baseline — collect a starter set or pick a readable metric |
| Returns a plausible number you can't trace to a source | Can't tell signal from coincidence | ❌ Investigate — an untraceable reading measures nothing |

## The loop

1. `chmod +x <vision-name>/metrics/<metric>/measure-outcome.sh` and run it.
2. Read the **full output**, not just that it exited 0 — confirm the number traces to a
   real source (the right rows, the real funnel, actual transcripts).
3. **Wrong reason** (mis-wired, no access, placeholder) → fix the probe or its access and
   re-run. Access is a *pointer* problem (which env var, who owns the credential), never a
   secret committed to the file.
4. **Genuinely unobservable** (no event exists, no users to interview yet, the number is
   nowhere) → the metric isn't measurable yet. Either instrument it (add the event — which
   may itself become an early bet) or choose a metric you *can* read today. A vision you
   can't measure is a vision you can't steer.
5. **Clean reading** → write line 0 of `readings.log`:
   `<YYYY-MM-DDThh:mm> | <value> | baseline | -`
   (the trailing `-` is the provenance slot `/evaluate-outcome` later fills with
   `bet=<slug>` and `repo#branch @ sha`).
6. Show the human the number and narrate what it proves: *this* is what we're starting
   from, and *this* is the dial the bet is trying to move.

## Notes

- **The baseline is the denominator.** Every later reading from `/evaluate-outcome` is
  judged as movement *from this line*. A wrong baseline poisons every future verdict, so
  it's worth getting traceable now.
- **Elicited metrics still need a real baseline.** "≥3/5 interviews mention X" requires a
  starter set of transcripts to score today — even a small one. If none exist, the metric
  isn't readable yet; say so.
- **This is the step most likely to need project judgment.** Keep the heuristic fixed
  ("does the number trace to a real read of the metric?"); let the per-instrument examples
  evolve for the stack.
