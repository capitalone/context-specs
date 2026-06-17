# Oracle design

The oracle is the loop's **definition of done** — the single contract the dispatcher gates
on (Inv 8). Get it right and autonomy is safe; get it wrong and the loop ships nonsense or
never converges.

## The shape: hard, judge-capable, sentinel-cached
- **Hard.** The oracle *blocks* the implement→PR transition. Exit 0 or no PR. There is **no
  "soft" oracle** in this design — a non-blocking advisory check is the *reviewer's* job, one
  phase downstream (the `/address-feedback` loop posts findings the human reads at merge).
  Don't duplicate the reviewer inside the oracle.
- **Judge-capable.** The per-work-item `run-prd-test.sh` may mix deterministic shell checks,
  an LLM-as-judge (grading against `loops/<ns>/oracle.md`), and project-native tests. This is
  the same contract as the `prd` loop's runner — "runnable" never forces everything into
  unit-test shape.
- **Sentinel-cached.** The dispatcher runs the runner only until it first goes green, then
  commits+pushes `specs/<f>/.prd-passed`. An LLM-judge runner is non-deterministic and costs
  tokens; without caching it would re-run every tick and could flip 0→1 and wrongly re-kick
  implement. Forward-only (Inv 9); CI, the reviewer, and the human merge cover later
  regressions. (This caching is already in the template — the dispatcher writes the sentinel,
  not the skill, because only the dispatcher's gate observed green.)

## Every loop keeps a hard floor
Refuse to generate a loop with zero hard gates. The baseline `local-checks` gate (auto-wired
beneath the oracle in the template) is the minimum floor — even a judge-only loop must clear
"it compiles + local-checks pass." A loop whose only gate is a soft judgment is an
all-vibes loop; the human would inherit 100% of verification, defeating the point.

## Authoring `loops/<ns>/oracle.md` (the judge rubric)
The rubric is a *passive* file, read by the runner's judge leg — not auto-loaded, not
injected. Three sections:
- **What the judge sees** — the focused context for *this* namespace (the diff, the PRD's
  Definition of done, a relevant Expert shard, a fixture). A judge with narrow, correct
  context beats one drowning in the repo.
- **Pass/fail criteria** — the bar, in observable/behavioral terms.
- **Known-tricky cases** — the failure modes the judge gets wrong for this namespace, with
  the right call spelled out. This is where most oracle tuning lands over the loop's life.

## Tuning the oracle later
An oracle-rubric edit changes the definition of done. Two safeguards:
- **Re-run the planted-event verification** (`verify-the-loop.md`) before merging a rubric
  change — the inverse of `/intent`'s fail-for-the-right-reason check.
- **Forward-only caching protects in-flight work**: an item that already passed stays passed;
  only not-yet-judged items see the new rubric. So a rubric change can't retroactively
  re-open work — the same property that makes `.prd-passed` safe.

The oracle rubric is loop machinery, so `learn` never rewrites it (no self-learning on
loops). A human tunes it; `learn` may only *suggest* changes in its PR prose.
