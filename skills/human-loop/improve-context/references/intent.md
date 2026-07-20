# `/intent` — the input lever

The context that goes *into* the chain: the PRD and the runnable definition of done, and how a
project raises their quality over time.

Every other lever shapes how the harness *builds*. This one decides **what it builds toward.** The
project-owned copy at `.claude/skills/intent/` produces the chain's two inputs:

- **`prds/<f>/prd.md`** — the *why* and the *what*. Prose that gives the downstream chain enough
  context to understand what needs to exist.
- **`prds/<f>/run-prd-test.sh`** — the executable definition of done. **The runner *is* the goal
  the harness converges on.**

That second one is the whole lever. The harness doesn't converge on the PRD's prose, and it
doesn't converge on what you meant — it converges on the runner, literally. Whatever the runner
accepts is what "done" means.

**This lever is more project-specific than any other.** `/intent` is not symlinked like the other
skills — `env-init` **copies** it into `.claude/skills/intent/` precisely so the project can edit
it. At install, `env-init` offered a choice: tailor the seams then (scanning the repo and citing
evidence for every line), or take the generic version and **customize later by editing**. This
lever is that "later."

So the first thing to establish is **which choice this project made, and how far its reality has
moved since.** A project that tailored at init has seams grounded in a scan that is now as old as
the install. A project that took the generic version has seams that were never grounded at all.
Either way you cannot improve this lever from a checklist — you have to go find out how this
project verifies things *today*.

## The principles

- **I1 — The harness converges on the runner, literally.** Not on your prose, not on your intent.
  Whatever `run-prd-test.sh` accepts is what "done" means, exactly and only.
- **I2 — Garbage in caps every lever downstream.** A vague PRD or a weak runner puts a ceiling on
  the whole chain, and no amount of Expert or `AGENTS.md` quality lifts it. When several levers
  look weak at once, suspect this one first.
- **I3 — A runner that passes for the wrong reason is worse than no runner.** The harness builds
  until green, then stops, and the PR looks finished. **The failure is silent and it looks like
  success** — which makes it the most expensive defect in the system.
- **I4 — Right-reason is the spine.** A runner must fail before the feature exists, *for the
  reason the feature addresses*. One that fails because of a typo, or passes because it asserts
  nothing, proves nothing — and the harness will happily converge on it.
- **I5 — Over-specification is the quieter defect.** A runner that pins implementation detail
  forces the harness to fight a constraint you never meant, burning attempts on a shape you didn't
  care about. It's harder to see than a weak check because the runner looks rigorous.
- **I6 — Fix the recipe, not the feature.** A better runner helps one feature; a better recipe
  helps every future one. The durable half of every improvement here is a project-owned reference
  file, never a single feature's artifacts.
- **I7 — Verification strategy is work-type-specific.** A feature has new observable behavior to
  assert. A refactor has none — an end-to-end test proves nothing there. There is no single runner
  shape, and mixing shapes in one runner is normal.
- **I8 — Explore before you prescribe.** Whatever the seams say today was written at install time
  at best, and the project has moved since. A subagent reading this project's real test setup finds
  what's actually there; a hardcoded list of frameworks only fits the projects it happens to match.
  `env-init`'s rule holds here too: **never invent a command you didn't see evidence for.**

## How to guide the user

**Present the menu first. Do not run a scan the human didn't choose** — an unbidden audit grades a
project nobody asked you to grade. Read the six options with what each improves, let them pick,
then run only that one.

| # | Improvement | What it improves | Typical cost |
|---|---|---|---|
| 1 | **Over-specification audit** | Deletes runner checks that pin *how* instead of *what* | Minutes |
| 2 | **Environment-failure triage** | Stops environment gaps from masquerading as absent features | Minutes |
| 3 | **PRD template fit** | Promotes the block always hand-added; deletes the always-empty one | Minutes |
| 4 | **Elicitation checklist** | The project dimensions every PRD here must address | Minutes–hour |
| 5 | **Runner-recipe fit** | Rewrites the cookbook in this project's own stack | An hour+ |
| 6 | **Work-type strategies** | A verification strategy per work type | An hour+ |

1–3 are cheap and mostly *delete or trim* — lead with them when the human has no preference.

**One cheap check first, though, because it re-orders the menu.** Look at whether the seams in
`.claude/skills/intent/references/` were tailored to this project or left generic — a minute's
read tells you. If they're still generic, the project took `env-init`'s "customize later" branch
and never came back; **5 is then the highest-value item on the menu**, because the other five tune
a cookbook the project isn't really using. If they were tailored, treat 5 as a drift check instead
and the cheap-first ordering stands.

6 is the largest, and it's the one that covers work types a feature-shaped cookbook won't handle.

**Use subagents to explore, not a hardcoded checklist (I8).** Every scan below dispatches
`Explore` agents over the project's PRDs, its test setup, and its history. Give each subagent a
slice and a schema for what to report, run them concurrently, and synthesize. What you're looking
for is always the same shape: **where has this project's reality drifted from what its seams say?**

**Where improvements land.** All six end in an edit to a seam under
`.claude/skills/intent/references/` — the project's own committed copy, never the canonical
template in the harness repo and never a feature's own artifacts (I6):

| Seam | Carries |
|---|---|
| `references/elicitation.md` | The Q&A style — what gets drawn out, when a PRD is offered |
| `references/prd-template.md` | The PRD skeleton and its optional blocks |
| `references/runner-recipes.md` | The per-check-type cookbook and work-type strategies |
| `references/right-reason.md` | What counts as a right-reason failure on this stack |

---

### 1. Over-specification audit

**What it is.** Read this project's past `run-prd-test.sh` files and ask of each check: *does this
assert what the feature does, or how it was built?* A check that greps for a specific function
name, or asserts a file exists at one of several equally valid paths, is pinning implementation.

**Why it pays.** The harness must satisfy the runner. When a check encodes a shape you never cared
about, the harness spends attempts contorting the implementation to match it — and you don't find
out, because from the outside it just looks like a hard feature. This is I5: the runner looks
rigorous, which is exactly why nobody rereads it.

**Process.**

1. **Fan out over past runners.** Give subagents `prds/*/run-prd-test.sh` and ask each to
   classify every check as *behavioral* (observable from outside — routes, output, files the
   feature is *about*, exit codes, DB state) or *structural* (asserts an internal name, path, or
   call shape).
2. **For each structural check, ask whether the pin was load-bearing.** Sometimes it is: a PRD
   whose whole point is "the config lives at `config/app.toml`" should assert that path. The
   question is whether the PRD's *intent* was about that shape, or whether the check just happened
   to encode the first implementation someone imagined.
3. **Cross-check against what the harness actually built.** Where a structural check exists and
   the merged implementation matches it exactly, look at whether the harness had a choice — a
   check that permitted only one design got only one design.

**The fix.** Two halves, and the second is the durable one (I6). Loosen the checks in any runner
still in flight. Then add a behavior-not-implementation rule to `runner-recipes.md` **with a real
example from this project's own runners** — a generic warning teaches less than one line of the
project's own over-specified check next to its behavioral rewrite.

**Produce nothing when** past runners assert only observable behavior. Say so; the discipline is
holding.

### 2. Environment-failure triage

**What it is.** `/intent`'s right-reason loop asks whether a runner fails *because the feature is
absent*. This scan finds the failures where the honest answer is **"no — the environment just
wasn't ready"**, and routes each one to the artifact that should have prevented it.

**Start from `scripts/bootstrap-worktree.sh`.** That script is the project's own written answer to
*"what does this project need in order to run?"* — which is exactly the question this item asks.
Reading it beats inferring the answer from failure archaeology.

**Why it pays.** Generic wrong-reason failures are loud — a typo announces itself. The dangerous
ones are quiet and environmental: a port collided with the human's dev server, migrations hadn't
run in the worktree, a secret exists locally but not where the harness executes. Each *looks* like
the feature is missing. The author confirms right-reason, commits, and the harness inherits a
runner that can never go green — or worse, one that goes green the day someone fixes the
environment, feature still absent (I3).

**The framework already predicts this failure and it is not hypothetical.** `harness-lib.sh:26-29`
says a bare worktree makes "the PRD runner … fail for reasons unrelated to the work," and
`env-init/references/worktree-bootstrap.md:88-90` warns that a bootstrap failing silently
"surfaces later as a confusing PRD-runner failure." Note also that `harness-lib.sh:35-37`
downgrades a bootstrap failure to a stderr `WARN` **and proceeds** — so nothing stops a
half-provisioned worktree from running the feature. The runner is where the damage shows up; the
provisioning is where it starts.

**Process.**

1. **Read `scripts/bootstrap-worktree.sh` first.** Read the generated section **below** the
   `--- project-specific provisioning below ---` marker; the deterministic header above it is
   canonical and off-limits (`worktree-bootstrap.md:19`). Inventory what it provisions: which
   gitignored files it copies, what it installs, what codegen or migrations it runs.
2. **Diff the runners' needs against that inventory.** Extract what past runners assume is
   running, seeded, migrated, authenticated, or set in env. **The gap between the two lists is the
   finding** — a runner needing something bootstrap never provisions is a build waiting to fail.
3. **Confirm against STUCK trails.** Dispatch a subagent over past STUCK PRs and harness logs
   (`stuck-forensics.md`) for runs whose failure was environmental. Evidence that a gap already
   cost a build promotes it to the top of the list — but a gap found in step 2 is real whether or
   not it has bitten yet.
4. **Check the loud-failure property.** Does bootstrap exit non-zero with a clear message when a
   step fails, per `worktree-bootstrap.md:88-90`? A silent bootstrap is a finding on its own, with
   no STUCK required. Be precise about what loudness buys, though: since the caller downgrades the
   failure to a `WARN`, a loud message doesn't *stop* the run — it puts the real reason in the
   trail instead of leaving a confusing runner failure as the only evidence.

**The fix — three destinations, and the ordering is the point.** Reach for the last one last:

| What you found | Where it goes |
|---|---|
| Bootstrap **should** provision it and doesn't | Add the step to `bootstrap-worktree.sh`'s generated section |
| Bootstrap tries and fails **silently** | Fix its error handling — exit non-zero with a message naming the step |
| Genuinely un-provisionable (a third-party service, a credential that can't leave a vault) | **Then** a trap entry in `right-reason.md` |

**Prefer the bootstrap fix, hard.** A trap entry teaches every future human to *recognize* the
failure forever; a bootstrap fix *removes* it, once, for every future feature. Writing a trap entry
for something bootstrap should have installed is prose compensating for a defect another artifact
should carry — `harnessability.md`'s H2, committed against a script instead of a folder.

When a trap entry *is* right, append it below `right-reason.md`'s generic rows with a concrete
symptom: *"`ECONNREFUSED` on 5432 → the test DB isn't reachable from a worktree; this is a wrong
reason, not an absent feature."* That file's heuristic is fixed; its examples are the hackable
part, and it says so.

**The bootstrap script is yours to edit — the header is not.** Its body is explicitly
project-owned ("The human owns it", `worktree-bootstrap.md:91`); the `context-specs link` header is
canonical and stays. Edits are still bound by Invariant 6: secrets copy source-checkout → worktree,
never the reverse, never delete. And it must stay idempotent and non-interactive — it runs
unattended in the loop.

**Produce nothing when** bootstrap already provisions everything the runners need and fails
loudly. Note this is now a *checkable* claim rather than a hopeful one — step 2 is a diff, so an
empty result means the two lists genuinely match, not that no STUCK has happened yet.

### 3. PRD template fit

**What it is.** Compare `prd-template.md`'s blocks against the PRDs this project actually
produces. Two findings only: a block that gets **hand-added every time** (promote it), and a block
that sits **empty or boilerplate every time** (delete it).

**Why it pays.** This is the cheapest item on the menu and it cuts both ways. A block always added
by hand is a question the elicitation should have asked — every PRD pays for the omission
separately. An always-empty block is noise the downstream chain reads on every feature, and
boilerplate teaches the reader to skim, which is how the *signal* sections get skimmed too.

**Process.**

1. **Fan out over `prds/*/prd.md`.** Ask subagents to report, per PRD, which template blocks are
   present, which are substantive, and which content appears that the template never asked for.
2. **Rank by frequency.** A block hand-added twice is a coincidence; five times is a missing
   template section. Same bar in reverse for deletion.
3. **Check the always-empty ones against intent before deleting.** A block that's empty because
   the feature genuinely had no non-functional requirements is fine and stays. A block that's
   empty because nobody knows what to put there is noise.

**The fix.** Promote or delete in `prd-template.md`. If you promote, also check whether
`elicitation.md` asks the question that fills it — a template section nobody is prompted for gets
hand-added forever.

**Produce nothing when** the template matches what PRDs actually contain. Say so.

### 4. Elicitation checklist

**What it is.** Find the cross-cutting dimensions that recur in this project — tenancy, auth,
migrations, feature flags, i18n, audit logging, rate limits, whatever this codebase actually has —
and add them to `elicitation.md` as questions the Q&A should raise.

**Why it pays.** A PRD that never mentions multi-tenancy produces a feature that works for tenant
one and breaks for tenant two. The harness didn't fail — nothing in its input said tenancy
existed, and it converged on a runner that never checked. **This is I2 in its purest form:** the
defect is an *absence* in the input, so it's invisible everywhere downstream. Nobody finds it by
reading the PR.

**Process.**

1. **Find the dimensions from the code.** Dispatch subagents over the codebase asking what
   cross-cutting concerns every feature has to honor — what does most request-handling code touch
   that isn't its own domain? Middleware, base classes, and shared context objects are where these
   live.
2. **Confirm from past PRDs and their outcomes.** Which of those dimensions did past PRDs address,
   and which got silently skipped? A dimension the code enforces everywhere but PRDs never mention
   is the top candidate.
3. **Weight by what actually broke.** If a merged feature needed follow-up work for a dimension
   the PRD never raised, that dimension goes on the list first — you have proof.

**The fix.** Add the dimensions to `elicitation.md` as questions to raise **when relevant**, not a
form to march through. That file's whole thesis is that a person who feels heard gives you more
than a person being interviewed — a checklist bolted on top would fight it. Frame them as things
to listen for, with the note that most won't apply to any given feature.

**Produce nothing when** the project has no strong cross-cutting dimensions, or past PRDs already
address them consistently.

### 5. Runner-recipe fit

**What it is.** Ground `runner-recipes.md` in this project's real verification stack — either for
the first time, if the seams were left generic at install, or as a drift check if `env-init`
tailored them and the stack has moved since.

**Why it pays.** The recipes are where `/intent` gets its answer to *"what shape of check can this
project actually run?"* When they don't describe this project, `/intent` improvises a runner per
feature — so verification shape drifts across features and **nothing accumulates.** The project
never develops verification taste; it re-derives it every time, and each derivation is only as
good as that one conversation.

Two ways this goes wrong, and they want different scans:

- **Never grounded.** The project took `env-init`'s "customize later" branch. The recipes are a
  plausible cookbook for *a* project, not necessarily this one — and plausible-but-wrong is worse
  than absent, because it reads as authoritative.
- **Grounded once, then drifted.** The tailoring cited real evidence at install; the project has
  since changed test runner, added a framework, or changed how the app boots. This is the more
  common case on a mature project, and the tell is a recipe naming a command nobody runs anymore.

**Process.**

1. **Read how the project verifies itself.** Subagents over CI config, test directories, scripts
   in the package/build manifest, and any `local-checks.sh`. Report: test framework(s), the
   command that runs them, the command that builds, how a focused single test is invoked.
2. **Read how the app boots — starting with `scripts/bootstrap-worktree.sh`.** What starts it, on
   what port, what does it need first (migrations, seed data, env file, a service dependency)?
   Bootstrap answers something CI configs and manifests can't: **what is already provisioned before
   the runner starts.** A recipe that re-installs deps or re-runs migrations bootstrap already did
   is slow at best and destructive at worst.
3. **Find the fixture and golden-file conventions.** Where do test fixtures live, how are golden
   files compared, is there a snapshot tool? A runner should mirror what the project already does,
   not import a new convention.
4. **Check the judge is available.** Is `claude -p` usable in the environment where the harness
   runs these runners? If not, the LLM-judge recipe needs a different shape or a note, and the
   fuzzy criteria have to land as native tests instead.
5. **Diff the scan against the current recipes.** Report which recipes match what you found, which
   name commands that no longer exist, and which have no counterpart in this project at all. Where
   `env-init` cited evidence for a tailored line, check whether that evidence still holds.

**The fix.** Rewrite the recipes around the project's real commands, **citing the evidence for each
one** — that's `env-init`'s standard and it applies just as much to a later edit. Keep the
recipes' *structure* (deterministic first, judge on the residue, native test when one fits); that
ordering is stack-independent and load-bearing. Two things must survive any rewrite: `set -euo
pipefail`, and a one-line failure reason per check — both exist so wrong-reason failures are
visible in the right-reason loop.

**Produce nothing when** the recipes already name the commands this project runs. On a project
tailored at install and stable since, this is the expected outcome — say so rather than
paraphrasing working recipes to look productive.

### 6. Work-type strategies

**What it is.** Different kinds of work need different proofs. Find which kinds this project
actually files, and give each one a verification strategy in `runner-recipes.md`.

**Why it pays.** A cookbook written around **features** — new observable behavior, so assert the
behavior — covers the common case and quietly fails every other one. The failure is silent,
because you can always *write* an end-to-end test for a refactor. It just proves nothing (I7).
Check whether this project's recipes are organized by check *type* (deterministic / judge /
native) alone; if so, nothing in them tells `/intent` that the work type changes the strategy.

The strategies, by work type:

- **Feature** — new observable behavior. Drive it end-to-end and assert the system's output. The
  default recipes handle this.
- **Refactor** — **no new observable behavior**, which is the entire point. An end-to-end test
  that passes before *and* after proves the refactor didn't happen as easily as it proves it did.
  Two shapes work: characterization/golden tests that pin current behavior and must stay green, or
  `claude -p` as judge with a tuned rubric — *behavior unchanged, shape improved* — pointed at the
  diff. The judge is doing real work here that a deterministic check can't: "shape improved" is
  exactly the kind of criterion that needs taste.
- **Bugfix** — the regression test that fails **now**, for the bug's reason. This work type has
  the cleanest right-reason story on the menu: the failing test is the bug report.
- **API/contract work** — assert conformance against the contract, not against a hand-written list
  of routes. Recipe 4 in `runner-recipes.md` is the seed; make it native to the project's contract
  format.
- **Data migration** — assert the end state *and* that existing rows survived. The second half is
  the one people forget, and it's where a passing runner does real damage.

**Mixing is normal and often correct.** A refactor PRD that also fixes a bug wants a
characterization suite *and* a failing regression test. Don't force one shape per PRD.

**Process.**

1. **Find out what this project actually files.** Subagents over `prds/*/prd.md` and merged PR
   history, classifying each by work type. A project that only ever files features doesn't need
   five strategies.
2. **For each type with real volume, check what past runners did.** A refactor PRD whose runner is
   an end-to-end behavioral test is the signature finding here — report it with the specific PRD.
3. **Ground each strategy in the project's stack.** This item depends on item 5's answers: a
   characterization-test strategy is worthless if it doesn't name the project's actual snapshot
   tool.

**The fix.** Add a work-type section to `runner-recipes.md` covering only the types this project
files, each with a concrete recipe in the project's own commands. Then teach `elicitation.md` to
establish the work type early — the strategy can't be chosen if the type was never named.

**Produce nothing when** the project files only features and the default recipes fit them.

---

## What holds an intent improvement

- **The project-owned reference file is the durable half (I6).** An improvement that lands only in
  one feature's runner helps one feature and then evaporates. The test is simple: if the next PRD
  wouldn't benefit, you haven't finished.
- **`evals/intent/` is the enforcer — and unlike a codebase refactor, this lever already has one.**
  `evals.md` defines it: an absolute `PASS | FAIL` gate over a PRD + runner fixture, judging
  whether the PRD is unambiguous about the *what*, whether the runner would **fail for the right
  reason** before the feature exists, and whether the strategy fits the work type. Keep it thin —
  1–2 cases to start. The question is well-defined; the rubric takes iteration, and that iteration
  is the work.
- **The with/without variant is how you prove a recipe is load-bearing.** Strip a recipe the
  project standardized on, regenerate, and check whether the runner degrades. If it doesn't, the
  recipe was decorative and you've learned something worth more than the eval (`evals.md`).

**The post-mortem is what feeds all six.** After a feature ships or STUCKs, ask what the runner
failed to capture or over-specified. That answer names which menu item to run — and it's evidence,
which beats any scan.

## What an intent improvement unlocks downstream

Say these to the human — they're why an hour here compounds:

- **The whole chain's ceiling rises.** This is the only lever where that's true (I2). Improving the
  Expert makes planning better; improving the input makes *everything* better, because everything
  downstream is converging on it.
- **Verification taste accumulates instead of being re-improvised.** Once a work type has a
  recipe, every future PRD of that type starts from it. That's the difference between a project
  that gets better at specifying work and one that's equally good at it forever.
- **STUCKs get cheaper to diagnose.** When runners follow known recipes, a STUCK is a deviation
  from a known shape rather than a bespoke artifact you have to read from scratch
  (`stuck-forensics.md`).

## Before you edit anything — the gate

Every improvement route ends here. Investigation is free; the **first write**
is the moment the human decides. One rule, no exceptions to remember.

When you've finished investigating and know what you'd do, **stop and say so:**

> I have all the context I need — *\<one line: what you'd change and why\>*. Want me to enter
> plan mode, or keep brainstorming?

- **Plan mode** → call `EnterPlanMode`. Say the one-line summary *before* you call it: the
  approval prompt can't carry your reasoning, and that reasoning is what they're deciding on.
- **Keep brainstorming** → stay in it. Declining is a normal, common answer — often the finding
  needs another turn of thought, or they want to sit with it. Don't re-ask each turn; raise the
  gate again when you've genuinely learned something new.

## Hard nevers

- **Never run a scan the human didn't choose.** Present the menu, take their pick, run that one.
- **Never edit `prds/<f>/prd.md`.** The spec of record is off-limits — it's the artifact the whole
  chain contracted on. Improve the seams that produce the *next* one.
- **Never invent a command you didn't see evidence for.** `env-init`'s rule, inherited: cite the
  scan behind every recipe line you write. A recipe that doesn't run on this project is worse than
  none, because it reads as authoritative (I8).
- **Never leave a runner that can pass without the feature.** A check that asserts nothing, or one
  a fixed environment satisfies, is the silent failure this lever exists to prevent (I3, I4).
- **Never patch a live worktree to fix an environment failure.** The fix belongs in
  `scripts/bootstrap-worktree.sh` in the human's checkout, where it holds for every future
  worktree; patching a running one fixes a single feature and teaches the project nothing. Editing
  that committed script is fine and expected — its *body* is project-owned. Touching the harness's
  per-feature worktrees is not (C5).
- **Never fix only the feature.** A better runner on one PRD is not an improvement to this lever
  until it's in a project-owned reference (I6).
- **Never manufacture a finding.** A template that fits, a trail with no environmental traps, a
  project that only files features — each correctly produces nothing.
