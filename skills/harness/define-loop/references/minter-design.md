# Minter design

The minter (`/intent-<ns>`) is the human-attentive front of the loop: it turns an idea into
a claimable git work-item carrying an oracle. It's a specialization of `/intent` — same
discipline, three namespace differences.

## The three differences from `/intent`
1. **It stamps the namespace branch prefix.** `git checkout -b <ns>/<author>/<feature>` and
   `git push -u origin <ns>/<author>/<feature>`. That branch *name* is the loop's queue; the
   dispatcher claims it by atomic rename to `feature/<ns>/<feature>`. The prefix is what makes
   the namespace an explicit, git-native attribute of the work-item (Inv 2) — the dispatcher
   reads `<ns>` from the branch, and a future namespace-aware `learn` would read it from the
   merged branch.
2. **It starts the PRD from `loops/<ns>/prd-template.md`** — including that template's
   `## Loop conventions` steering section (below).
3. **Its runner wires the LLM-judge leg to `loops/<ns>/oracle.md`** — the loop's judge rubric.

Everything else is identical to `/intent`, and the output layout is identical
(`prds/<feature>/prd.md` + `run-prd-test.sh`), which is exactly why the whole downstream
chain is reused unchanged.

## `## Loop conventions` — the loop's only steering surface
There is **no eager namespace memory** in this design (no injected per-namespace AGENTS.md).
A `<ns>` agent learns "how to behave in this loop" from exactly two places:
- the **phase skills** the loop runs (which `define-loop` chose), and
- the **`## Loop conventions`** section the minter stamps into every work-item's PRD.

So that section is load-bearing. Make it specific and behavioral — e.g. for a `bug` loop:
"Reproduce first with a failing check; make the smallest change that fixes it; do not expand
scope beyond the repro." The hard oracle is the backstop: if an agent ignores the steering
and over-reaches, the runner (e.g. a regression check) catches it. Weak steering is
affordable *because* the oracle is hard — but don't lean on that; write the steering well.

**Footgun to close at authoring time:** if the loop's behavioral difference isn't encoded in
either the phase skills or `## Loop conventions`, the loop silently behaves like a plain
feature build. Decide explicitly where the difference lives.

## Self-containment
The generated minter must be standalone (no cross-skill reference dependency). `define-loop`
copies `/intent`'s `references/runner-recipes.md` (the per-check-type cookbook for authoring
`run-prd-test.sh`) and `references/right-reason.md` (the fail-for-the-right-reason heuristic)
into `.claude/skills/intent-<ns>/references/`, adapting branch examples to `<ns>/`. The
namespace-specific bits (PRD skeleton, oracle bar) live in `loops/<ns>/` and the minter reads
them by repo path.

## The proof the minter still owes
The minter is not done until the runner **fails for the right reason** against today's code
(every check fails *because the behavior is absent*, not from a typo / missing dep / unrelated
breakage). This is the empirical proof the prose and the runnable oracle correspond — the
same gate `/intent` enforces, and the thing `verify-the-loop.md` re-checks at the loop level.
