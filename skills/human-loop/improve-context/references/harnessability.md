# Harnessability — the codebase as a context lever

The codebase itself as context: what makes it legible to a fresh agent, and
the refactors that improve it.

Every other lever is an artifact **about** the code. This one is the code. It is the
highest-volume context any agent reads, and the only context that **cannot lie**: a folder named
`auth/` containing only auth *is* that claim, and it can't drift out of sync with itself. Prose
can rot. Structure can't self-contradict.

**Harnessability** is the property you're improving: how amenable the codebase is to an agent
reasoning about it directly — from names, structure, and neighbors, without asking a person and
without reading everything. A harnessable repo answers four questions from the visible surface
alone: *where does this change belong, what precedent do I follow, what constraints apply, how do
I prove it's right?*

## The principles

- **H1 — The ladder: prose → structure → lint.** Three ways to carry a fact. Prose (a shard, an
  `AGENTS.md` line) reaches anything but rots and costs tokens every session. Structure (a name, a
  folder, a file's home) is free — the agent sees it during agentic search regardless — and can't
  self-contradict, but decays as new code lands. A lint cannot be violated, but only reaches
  what's mechanical. **Every move is downhill.**
- **H2 — A shard that describes structure is a bug report against the structure.** A shard reading
  *"auth helpers live in `utils/auth.ts`; date code is also in `utils/`"* exists to compensate for
  a folder that doesn't say what it holds. Split it and the shard becomes unnecessary. **This is
  an improvement that deletes context instead of adding it** — and the deletion is a correctness
  upgrade, not just a token saving, because the thing you deleted was the thing that could go
  stale.
- **H3 — Agents imitate their nearest neighbor.** Code reaches the agent by **agentic search** —
  grep and glob, not an index. You can't prune it like an `AGENTS.md` line or route to it like a
  shard. The only knob is: *how far does an agent search before it finds the right thing, and is
  the first thing it finds the one you'd want copied?* The job is to make the nearest neighbor the
  right neighbor.
- **H4 — This is horizontal work, never feature work.** The rest of the framework forbids agents
  to refactor (`/fix-local-checks`, `/address-feedback`: "Never refactor or add features") — that
  stops an agent mid-task from wandering off its spec, and it stands. **This is different:** the
  human is present, the refactor *is* the task, and it changes no behavior. The moment it changes
  what the product does, it's a PRD and it belongs to the harness.
- **H5 — The human decides what's canonical; you do the work.** They're not here to do the
  cleaning. Deciding which of three route shapes is *the* route shape is judgment only they have,
  and understanding it is the point of their presence. The migration is downstream of the
  decision.
- **H6 — Producing nothing is a correct outcome.** A menu that always finds something is a menu
  that manufactures findings. A legible repo, a variant that's load-bearing, a name you'd merely
  have chosen differently — each correctly produces no refactor.
- **H7 — Structure decays; say what holds it.** The harness is the entropy source: every
  autonomous PR nudges toward one more variant, one more file in `utils/`. Legibility decays
  *proportionally to how well your harness is working*. So for every refactor, name what holds it
  — see **What holds a refactor** below.

## How to guide the user

**Present the menu first. Do not run a scan the human didn't choose** — an unbidden survey grades
a project nobody asked you to grade. Read the seven options with what each improves, let them
pick, then run only that one.

| # | Refactor | What it improves | Typical cost |
|---|---|---|---|
| 1 | **Renaming** | Names predict contents; search terminates faster | Minutes |
| 2 | **Expert-compensation scan** | Deletes prose the structure already carries | Minutes |
| 3 | **Source-of-truth integrity** | Expert, AGENTS.md, code, and lints agree — and no rule claims more than it enforces | Minutes |
| 4 | **Pattern singularity** | One way to do each recurring job | An hour+ |
| 5 | **Establish a canonical pattern** | Gives a recurring shape a name and an exemplar | Rare, careful |
| 6 | **Boundary visibility** | Layers are real, not aspirational; best lint candidate | An hour+ |
| 7 | **Change locality** | One domain change stays in one place | Largest; bound it |

1–3 are cheap and mostly *delete* things — lead with them when the human has no preference. 4, 6,
and 7 are migrations. 5 is the one that can make things worse; read its warning before offering
it.

**Use subagents to explore, not a hardcoded checklist.** Every scan below dispatches `Explore`
agents over slices of the repo. A fixed list of suspicious folder names finds only the repos that
happen to match it; a subagent reading the actual tree finds what's actually there. Give each
subagent a slice and a schema for what to report, run them concurrently, and synthesize.

---

### 1. Renaming — make the name the claim

**What it is.** Rename a thing to what it is. Move a file into the folder its name already
implies. Split a folder that holds several unrelated concepts under one name. The highest ratio
on the menu: near-zero risk, immediate effect on every future search.

**Why it pays.** A folder whose name predicts nothing teaches nothing — and it accretes, because
it's the path of least resistance for every future agent. The name is what the agent reads
*before* it opens anything, so a lying name costs a search every session, forever.

**Process.**

1. **Name→content probe.** Give a subagent **only the folder tree** — no file contents — and ask
   it to predict what lives in each folder and what may import what. Then diff its answer against
   reality. **Where it guesses wrong, the name is lying.** This is the measurement: harnessability
   is otherwise something you can only feel, and this makes it a diff. It's also faithful —
   predicting-from-names is exactly what an agent does before opening anything.
2. **Concept-count sweep.** Dispatch subagents across the tree; for each folder they read the
   files and report the **distinct concepts** inside. A folder holding three unrelated purposes
   under one name is a split candidate: *"`src/utils/` holds 11 files spanning auth, date
   formatting, and HTTP retry — three purposes, one name."*
3. **File-vs-export mismatch.** Ask a subagent for files whose name doesn't match their primary
   export or responsibility, and files that sit outside the folder their name implies.

Generic names (`utils/`, `helpers/`, `common/`, `shared/`, `misc/`) are a *hint*, not a finding —
they mean "I didn't decide." Confirm by reading the contents. A small folder of genuinely shared
primitives is fine and stays.

**The fix.** Rename, move, or split — one concept at a time, using the repo's own rename tooling,
with build and tests green between each. No behavior change.

**Produce nothing when** names predict contents. Say so and offer another lever.

### 2. Expert-compensation scan

**What it is.** Read the Expert's (long-term memory) shards and ask of each: *does this exist only to explain where
things live, or what a name really means?* Prose that maps the tree (`db/` — all database access;
`client.ts` — the client) is the tell.

**Then check the structure it describes, because there are two outcomes and only one is a
refactor:**

- **The name is lying** → the shard is a *receipt* for illegible structure; the developer paid
  tokens to work around a name. Refactor (option 1), then delete the shard.
- **The name is already fine and the shard just restates it** → this is the common case, and
  there's **nothing to refactor**. The structure already carries the fact; the prose is a
  duplicate that costs tokens and can now drift out of sync with a tree that can't. **Just trim
  the shard.** A free win — don't manufacture a refactor to justify the finding.

Either way the deletion is real, which is what makes this the highest-value cheap probe you have.

**Distinguish honestly — most shards near structure are legitimate.** A shard carrying *why* the
boundary exists, what breaks if you cross it, or where it's heading is doing work structure can't,
and it stays:

> `invariant-db-layer-boundary`: states the rule, explains **why** (one seam, so a future
> migration isn't a repo-wide hunt), and names the lint that enforces it. Prose for the why,
> structure for the where, lint for the teeth. **All three rungs, each doing only its own job.**
> That shard is not debt — it's the ladder working.

Only the *where*-without-*why* half is debt.

### 3. Source-of-truth integrity

**What it is.** A four-way cross-check: do the **Expert**, **`AGENTS.md`**, **the code**, and
**the lints** all say the same thing? Every rung of the ladder is a claim about the same project,
and they drift apart silently — nothing in the system compares them to each other.

**Process.** Use a subagent to extract every claim about structure or rules from the Expert shards
and `AGENTS.md`. For each claim, check it against the code and against the lints, then classify:

- **All agree** → nothing to do. Most claims land here, and that's the healthy outcome.
- **Prose contradicted by the code** → **highest severity.** A stale rule is read *confidently*,
  and the agent has no signal it's wrong. Fix or delete.
- **Prose broader than the lint that backs it** → an **overclaim**. See below — this one has its
  own shape.
- **Lint with no prose** → usually fine (structure and teeth, no rot). Add a *why* shard only if
  agents keep fighting the lint without understanding it.
- **Code convention nobody wrote down** → candidate `pattern-*` shard, or leave it to the
  exemplar. Prefer the exemplar (H2).

**The overclaim case.** When prose cites an enforcer, compare the enforcer's **actual scope**
against the claim. They always drift in one direction: the prose is broader.

> Real example: a shard reads *"No file in `app/` **(or elsewhere)** imports `drizzle-orm`
> directly."* The lint that enforces it greps `app/` and nothing else. Everything outside `app/`
> is unguarded — and a file was already sitting in the gap.

This is rung 1 overclaiming against rung 3, and it's the worst failure the ladder has: the agent
reads a rule, believes it's universal, and nothing catches it when it isn't. Silent, confident,
wrong. Cheap to detect — read the lint's match scope, read the claim, compare. Two fixes, and the
**human picks**, because it's a decision about the invariant, not a typo:

- **Narrow the prose** to exactly what's enforced, or
- **Widen the lint** to what's claimed — which means fixing the violators already sitting in the
  gap first (`lints.md`: never auto-grandfather).

**The fix elsewhere is usually a delete or a trim, not a refactor.** When two sources disagree,
the human decides which one is right — that's a decision about intent, not a cleanup.

### 4. Pattern singularity

**What it is.** Search the **codebase** for its recurring patterns and count how many distinct
shapes each one has. **N > 1 means the next agent picks by coin flip.**

Start from the code: the Expert's `pattern-*` shards and recent PRDs are useful *hints* about which patterns should be singular, but the code is the source of truth about what's actually there — including patterns nobody ever wrote down.

**Process.**

1. **Slice the repo and fan out.** Give each subagent one slice — HTTP routes and handlers, data
   access, error handling, config/env access, background jobs, validation, logging, auth checks,
   test setup — and ask it to report every instance and group them by shape.
2. **Report shape counts, with the split visible:** *"3 ways to define an HTTP route: the
   `createRoute()` builder (7 uses), a bare express handler (2), one hand-rolled middleware chain
   (1)."*
3. **Check the nearest-neighbor trap.** For the place new code would land, is the **closest**
   existing example the one you'd want copied? Deprecated-but-canonical-looking code is the
   deadliest thing in an agent codebase: it reads as an exemplar and the agent has no way to know
   it's dead. The lone one-off is often the most dangerous neighbor, not the least.
4. **Classify each N > 1** before proposing anything:
   - **Drift** — same job, different shapes, no reason. Consolidate.
   - **Load-bearing** — genuinely two cases. Don't consolidate; instead ask whether the *names*
     carry the distinction, so an agent can tell which case it's in.
5. **Weight by what the harness did recently.** If the Expert says `routes/` and the last two
   merged PRs used `handlers/`, the harness is drifting away from stated intent *right now* —
   that's the most urgent finding this menu can produce.

**The fix.** The human picks the canonical shape (a minute). You migrate or delete the losers (the
hour). Then consider a lint.

### 5. Establish a canonical pattern

**What it is.** Where option 4 consolidates variants that already exist, this one creates a new pattern — which gives it an exemplar future agents can copy. It's powerful precisely because you're authoring the thing every future agent will imitate.

Patterns worth considering:

- **Behavioral** — Strategy, Observer, Command, State, Template Method
- **Creational** — Factory, Builder, Singleton, Dependency Injection
- **Structural** — Adapter, Decorator, Facade, Composite
- **Architectural** — Layered, Event-driven, Fan-out, Repository, Service Layer
- **Integration** — API Gateway, Circuit Breaker, Retry, Saga
- **Anything else** the subagent finds worth naming — this list is a prompt, not a menu.

**The warning — read this before offering the option.** This is the one item that can leave the
repo *worse*. Introducing a pattern the codebase doesn't need adds indirection and a second way to
do things, which is the exact defect this whole menu exists to remove. The bar: **a proposed
pattern must not violate the N > 1 rule from Pattern singularity — it must be first of its kind,
or retire the existing pattern it replaces.**

**Producing nothing is the expected outcome most of the time.** A healthy system needs very few
named patterns. Only propose one where the codebase is already reaching for it.

**Process.**

1. Subagent reads one module and asks: *is there an opportunity to apply a pattern that would be
   easily followed by future agents?* Require it to ground the proposal in **real sites** — the
   existing places that already almost do this, and which one is the best candidate exemplar. A
   pattern with no sites behind it is speculation, and speculation is how this option makes the
   repo worse.
2. Explain what the pattern is and why it would help (if any pattern found worth applying). Can go
   into details such as code snippets, but keep high level for now until you get into planning.
   Say plainly which existing shape it retires, or that it's the first of its kind. Always allow
   the user to give feedback and decide.

**No behavior change.** If adopting the pattern changes what the product does, it's a PRD.

### 6. Boundary visibility

**What it is.** Check whether the layers the project believes in are actually real. Does the repo
class get imported directly in the controller layer as well as the service layer? Would making the
boundary visible make the code more predictable?

**Why it pays.** An agent generalizes from local examples. If a layer is crossed in three places,
the agent's nearest neighbor teaches it that crossing is fine — and the boundary quietly stops
existing. This is also **the best lint candidate on the menu**: import direction is perfectly
mechanical, so it can land on the bottom rung and stay there.

**Process.**

1. **Establish the intended layering** — Use a subagent to research the Expert, `AGENTS.md`, and
   codebase structure to infer the intended layering.  You may find most modules / packages
   imports are consistent and follow the implied rules.  However, if there are outliers, this is
   where we need to investigate if we think it's intentional or not. If not, this is a refactor
   that can be done. **Report the outliers as a count of crossing import sites**, with the files
   named — the count is what tells you and the human whether this is a fix or a migration.
2. **Propose the refactor.** If there clearly was a refactoring opportunity from step 1, explain
   and propose it to the user. Not only the refactor code, but the lint that enforces it.  Explain
   how this will prevent future agents from violating this pattern going forward.  Always allow
   the user to give feedback and decide. The migration lands **before** the lint — a lint must
   pass clean against current code, so a green lint is the proof the crossings are all gone
   (`lints.md`).


### 7. Change locality

**What it is.** Does one domain change mostly stay within one understandable area? The smell: a
small feature requires edits across several generic folders with no visible connection between
them.

**Why it pays.** Locality is what lets an agent scope its own work. When a feature's files are
scattered, the agent either misses one (a bug) or reads the whole repo to be safe (tokens, and a
diff nobody can review).

**Process.**

1. **Backward, from history.** `git log --name-only` over recent feature merges; cluster files
   that change together. Files that always change together but live apart are a locality defect.
   Files sharing a folder that never change together are a false grouping — the folder name is
   organizing by *kind* where the work is organized by *domain*.
2. **Forward, from a plausible next feature.** Take one the human names and trace where the edits
   would land. Count the folders.
3. **Report the worst single cluster**, not all of them.

**The fix.** Colocate by domain. **This is the largest item on the menu and the one most likely to
turn into an open-ended migration** — bound it to one cluster, land it, and re-run rather than
starting a repo-wide reorganization.

---

## What holds a refactor

Structure decays (H7), so for each landed refactor, say what keeps it from drifting back:

- **Mechanically checkable → a lint.** The destination. Message quality is not optional
  (`lints.md`, `env-init/references/local-checks-design.md` — WHERE / WHAT / WHY / FIX /
  DON'T-CHEAT); a lint whose message doesn't read as a fix-prompt manufactures STUCKs. The lint
  must pass against current code before it wires in, so the migration completes first. This
  self-limits scope, which is useful: **you can't take on a migration you can't finish, because
  you won't get your enforcer.**
- **Not mechanical → name the drift risk out loud** and let the human decide knowingly. *"This
  will drift back; nothing enforces it"* is a legitimate thing to land, **said**. Don't pretend a
  refactor is durable when nothing holds it.

**Evals could hold the non-mechanical ones — but not yet.** An eval is a legitimate enforcer in
principle: a codebase-legibility case that reads worse before a refactor and better after would
catch drift the way a lint catches import direction. The eval suite doesn't cover codebase
refactors today (`evals.md` is per-lever over prose artifacts), and building that coverage is out
of scope. Mention it as the future home; don't promise it and don't build it here.

## What a refactor unlocks downstream

Say these to the human — they're why thirty minutes compounds:

- **A shard gets deleted or demoted.** The geography shard becomes unnecessary, or stops
  describing where things are and starts pointing at the canonical exemplar. Shorter, and it can
  no longer be wrong.
- **A global rule can become a local one.** You can only scope rules as well as your folders are
  scoped. Illegible structure forces rules up into eager, global `AGENTS.md`, where every line
  taxes every session. Fix the folder and the rule moves into a nested `AGENTS.md` that only loads
  when an agent goes there (`agents-md.md`).
- **The lint holds it forever**, for free, on every future PR.


## Before you edit anything — the gate

Every refactor route ends here. Investigation is free; the **first write**
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
  An unbidden survey grades a project nobody asked you to grade.
- **Never let a horizontal refactor become feature work.** No behavior change. The moment it
  changes what the product does, it's a PRD and it belongs to the harness — stop and say so.
- **Never introduce a pattern that adds a variant.** Option 5 must reduce the number of ways to do
  a job. One canonical pattern per module, never N>1.
- **Never land a lint before its migration completes.** A lint must pass against current code and
  never auto-grandfather violators; the green lint *is* the proof the refactor finished
  (`lints.md`).
- **Never manufacture a finding.** A legible repo, a load-bearing variant, a shard that carries a
  real *why* — each correctly produces nothing (H6).
