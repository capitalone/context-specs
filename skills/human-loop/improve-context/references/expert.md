# The Expert — the project's long-term memory

**Hackable seam.** The project's long-term memory and how to improve it. A project can annotate
this with its own conventions.

`.claude/skills/expert/` — a routing-table `SKILL.md` plus one small reference file per topic
("shards"). It is created by `env-init` from `assets/expert-skeleton/`, committed to the project,
and **owned by the developer**; `/learn` files behind them after every merge to main, and the
implementer's Reflect step after every slice. It holds all three kinds of long-term memory —
**procedural** (how to do a thing), **semantic** (what a thing is, what rules hold), and
**episodic** (what happened that one time) — plus **direction** the code hasn't reached yet.

**Long-term memory informs short-term memory.** `/spec-planning` consults it at the start of every
plan and `/intent` loads it to shape PRDs and runners. It is the prose rung of the ladder — the
developer's channel for steering the autonomous chain **without being in the room**. What's written
here shows up in every future plan.

**What makes this lever unlike the other five: it's lazy, so routing can fail independently of
content.** `AGENTS.md` is loaded into every session; code is reached by grep. Here a shard can be
correct, current, and well-written and still never reach an agent, because its `USE WHEN` line
didn't match the task or its routing-table row is missing — *a file not listed is invisible*. That
asymmetry is why half the menu below is routing work, and why the Tier-1 eval invokes the real
`/expert` in a sandbox rather than pasting the shard's text into the prompt (`evals.md`).

## The principles

- **E1 — Content is half the job; routing is the other half.** This is the only lever where a fact
  can be right and still not arrive. The `USE WHEN` line and the routing-table row are **first-class
  artifacts**, not bookkeeping — they are the retrieval query the agent matches against. A shard
  nobody opens scores exactly zero, and it does it silently.
- **E2 — One shard tunes the whole system; a code fix tunes one feature.** Every plan opens with
  this memory, so a shard's blast radius is every future feature. That ratio is why this is the
  biggest lever the developer writes, and why an hour here beats an hour almost anywhere else.
- **E3 — The ladder: if structure could carry it, structure should.** The Expert holds **what the
  code cannot say** — why a boundary exists, what you decided, where you're heading, what bit you
  last time. The codebase holds **where things go and what gets copied**. A shard explaining *why* a
  boundary exists is legitimate memory; one explaining *where* the code lives is debt — a bug report
  against the structure (`harnessability.md`). Prose can rot; a folder named `auth/` holding only
  auth can't.
- **E4 — The prefix is the routing signal.** Six prefixes, and the choice is a claim about what
  *kind* of knowledge this is: `how-to-*` (procedural) · `concept-*` (semantic, nouns) ·
  `pattern-*` (semantic, soft rules the code already follows) · `invariant-*` (semantic, hard
  rules — if mechanically checkable, a lint is stronger and the shard carries the *why* the lint
  can't) · `example-*` (episodic, cited from a real sha, never synthetic) · `decision-*`
  (forward-looking direction, carrying an **Until fulfilled** note, no status field — the file
  existing means adopted). `decision-*` is the one thing **nothing else in the system can carry**:
  code, lints, and `AGENTS.md` can only describe what is. Authority on the prefixes and their
  bootstrap rules: `/learn`'s `references/expert-structure.md`.
- **E5 — The memory is the developer's; `/learn` is the filer.** Human-authored edits are
  authoritative — `/learn` extends them, never second-guesses them (its P7). Encourage editing
  **rapidly and constantly**, direction included. **Never gatekeep an edit because "the code doesn't
  show it yet"** — that's precisely the memory nothing else can hold.
- **E6 — Reconcile, don't accumulate.** When reality *or intent* changes, edit or delete the shard.
  Never append a correction beside a wrong one — the agent has no way to tell which half won. A
  40-shard Expert with 6 stale shards is worse than a 10-shard one that's clean.
- **E7 — Producing nothing is a correct outcome.** A healthy Expert, a shard that carries a real
  *why*, a decision that's simply still pending — each correctly produces no edit. A scan that
  always finds something is a scan that manufactures findings.

**Severity, when you're ranking what you found: stale memory is worse than no memory.** An empty
Expert makes an agent go look; a wrong one makes it stop looking. It's read *confidently*, and
nothing in the trail signals it's wrong. Same ranking `harnessability.md` gives "prose contradicted
by the code" — a contradiction outranks a gap, every time.

## How to guide the user

**Present the menu first. Do not run a scan the human didn't choose** — an unbidden audit grades a
memory nobody asked you to grade, and this one is *theirs*. Read the options with what each
improves, let them pick, then run only that one.

| # | Move | What it improves | Typical cost |
|---|---|---|---|
| 1 | **Seed an empty Expert** | Nothing compounds until something's in it | An hour (interview) |
| 2 | **Routing audit** | Shards actually get opened; prefix and split/merge hygiene | Minutes |
| 3 | **Staleness audit** | Kills confidently-wrong memory | Minutes |
| 4 | **Decision review** | Fulfilled / live / dead — keeps direction honest | Minutes |
| 5 | **Extend procedural & semantic memory** | Fills the gaps the existing shards imply | An hour+ |
| 6 | **Write standing direction** | Steer the harness without being in the room | Minutes+ |
| 7 | **Demote down the ladder** | Shard → structure or lint; deletes prose that can rot | Varies |

**1 is a gate, not an option.** Check whether the routing table is empty before offering anything
else — on an empty Expert, 2–7 are vacuous and seeding is the only move that means anything. Say so
plainly rather than running an audit over nothing.

**These aren't all the same shape, and don't pretend otherwise.** 2, 3, 4 and 7 are *scans* that
start from a defect — dispatch subagents, report findings, the human disposes. **5 is generative and
conversational**: the only move that proposes *new* memory from a survey rather than from something
that went wrong, which is exactly why it carries its own validation gate. **6 has no subagent at
all** — standing direction exists only in the human's head, and this conversation is the only place
it can enter the system.

**Use subagents to explore, not a hardcoded checklist.** Every scan below dispatches `Explore`
agents over slices of the Expert and the repo. The Expert is *entirely* project-specific — a fixed
list of shard names or suspected topics finds only the projects that happen to match it. Give each
subagent a slice and a schema for what to report, run them concurrently, and synthesize.

---

### 1. Seed an empty Expert

**What it is.** The Expert ships as an empty skeleton — structure only, no invented content. Filling
it the first time is half code exploration (things the repo can tell you) and half interview (things
only the human can).

**Why it pays.** Until something is in it, every plan starts from zero and nothing in the system
compounds. On a fresh project this and the codebase are the only two levers that mean anything yet.

**Process.**

1. **Explore first, interview second.** Dispatch subagents over slices of the repo and have them
   report: the run/build/test commands and their real entry points; the module layering; the
   entrypoints and core abstractions with paths; constraints already enforced by lints or CI; and
   whether a real e2e path exists. **Bring findings to the human already drafted** — reviewing a
   wrong draft is faster than answering an open question, and it's a better use of their time than
   asking them to recite what the repo already says.
2. **Map onto the always-seed five** — `how-to-run-the-project`, `how-to-validate`,
   `how-to-add-a-feature`, `concept-architecture`, `concept-core-files`. Add `how-to-e2e-test` and
   `concept-verification` only on clear visible signal, and one `invariant-*` per rule the code
   *visibly* upholds; skip on uncertainty and let post-merge discovery promote it.
3. **Then interview for what code can't say** — direction, tribal knowledge, past scars, the
   boundary whose *why* isn't written anywhere.

**The fix.** Write the shards, each opening with a `USE WHEN:` line, each with its routing-table row
in the same commit. Respect the bootstrap rules from `expert-structure.md`: **soft cap ~15 files**,
and **zero `pattern-*`, `example-*`, or `decision-*` from a code scan.** Patterns need recurring
evidence across merges; episodic memory needs a real sha; a decision needs a human stating direction
— which is exactly what step 3 and move 6 are for.

**Produce nothing when** the Expert already has content — that's moves 2–7, not this one.

### 2. Routing audit

**What it is.** The measurement move for this lever, and the direct analogue of the name→content
probe in `harnessability.md`. Content correctness is not the question here; **discoverability** is.

**Why it pays.** Routing failure is invisible from the inside. A shard with a vague `USE WHEN` line
looks identical, in the repo, to one that gets opened every plan — the only difference shows up in
plans that quietly didn't use it. Nothing else in the system checks this.

**Process.**

1. **Cold-routing probe.** Give a subagent **only `SKILL.md`'s routing table** — no shard bodies —
   plus ~8 realistic planning questions for *this* project (draw them from recent PRDs or ask the
   human). Ask which files it would open for each. Then diff against which files *should* have
   opened. **Where it guesses wrong, the `USE WHEN` line is lying.** This is faithful because
   routing-from-the-table is exactly what `/expert` does before opening anything.
2. **Integrity sweep.** A second subagent reports: files in `references/` with no routing-table row
   (**invisible**); rows pointing at files that don't exist; broken or malformed wikilinks and
   orphans (`/learn`'s `scripts/check-expert-links.sh` is the mechanical check — broken fails,
   orphan warns).
3. **Shape mismatches.** Ask for shards whose **prefix doesn't match their content** (a `concept-`
   that's really a procedure, a `pattern-` stating a hard rule), shards covering **three unrelated
   topics** under one name (split — one topic per file is what makes single-question routing work),
   and **several tiny shards on one topic** (merge).

**The fix.** Rewrite `USE WHEN` lines to name the *task* an agent would be doing, not the topic;
add missing rows; split, merge, or re-prefix. All cheap, all high-yield.

**Produce nothing when** the cold probe routes correctly and the table is in sync. Say so — a
well-routed Expert is the healthy outcome, not a missed finding.

### 3. Staleness audit

**What it is.** Verify what the shards *claim* against the code at HEAD. Most shards describe the
code as it IS; those claims decay every time the harness merges.

**Why it pays.** See the severity note above — a contradicted shard is read confidently and stops
the agent from looking. This is the highest-severity defect this lever can have, and it's cheap to
detect.

**Process.**

1. **Fan out, one subagent per shard** (or per small group). Have each extract every **concrete
   claim** — file paths, symbol and export names, commands, shas, cited line ranges — and check each
   against HEAD.
2. **Report a verdict per claim:** `confirmed` · `drifted` (the thing moved or was renamed; the
   point still stands) · **`contradicted`** (the code now does the opposite). Rank contradicted
   first, and name the shard and the claim, not just a count.
3. **Skip `decision-*` shards mechanically, by prefix.** A decision describing something the code
   doesn't do isn't stale — that's its job. It's move 4's business.

**The fix.** Edit or delete (E6). Never append a correction alongside the wrong claim. If a shard is
mostly drift, ask whether the *why* underneath it is still true — often the durable half survives
and the citations were the rot.

**Produce nothing when** the claims hold. This is a common outcome on a project where `/learn` is
running well, and it's worth telling the human that the memory loop is working.

### 4. Decision review

**What it is.** Walk the `decision-*` shards and sort them into **fulfilled**, **live**, and
**dead**. `/learn` retires the fulfilled ones automatically after the merge that realizes them; only
a human, present, can judge one **dead**.

**Why it pays.** A decision the project walked away from is worse than no decision — it aims every
future plan at a target nobody is heading toward, and nothing in the automated loop will ever catch
it, because "no merge fulfilled this" looks the same as "not yet."

**Process.**

1. **Per decision, one subagent.** Is the stated target realized in code, partly realized, or
   untouched? Require **evidence** — the files that do or don't reflect it.
2. **Add the time signal.** `git log` the shard file and the area it names: how long has it been
   quiet, and has the surrounding code moved *away* from the direction while the shard sat still?
3. **Report; don't decide.** Present each as *"realized / partly realized / untouched since
   \<date\>, and here's what the code does now."* The judgment is the human's — that's the point of
   their presence.

**The fix.** Fulfilled → promote to a `concept-`/`pattern-` fact and delete the decision. Dead →
delete it outright. **Partly shipped** → promote the realized part to a fact and drop the rest;
that's the case people leave half-done. Live → leave it untouched, including its *Until fulfilled*
note.

**Produce nothing when** the decisions are simply still pending. Pending is the normal state of a
decision; don't read patience as abandonment.

### 5. Extend procedural & semantic memory

**What it is.** Survey what the Expert already teaches *and* what the code actually does, then
propose the shards the existing ones **imply but nobody wrote**. The memory usually stops where
whoever wrote it stopped, not where the project's recurring work stops.

**The warning — read this before offering the option.** Every other move on this menu starts from a
defect: something stale, unroutable, abandoned, or absent. **This one adds by extrapolation**, which
is how you produce shards that are plausible, well-written, and useless. And a useless shard is not
free: it's a permanent row on the routing table, which is read **in full on every consult**, so it
taxes routing precision for every *other* shard forever (E1). The bar: **grounded in real sites, and
through the gate below.** Producing nothing is a common and correct outcome here.

**Why it pays.** These gaps are invisible to every other move — nothing failed, nothing is stale, no
PR went STUCK. A `how-to-implement-a-route` with no sibling for the project's other recurring build
quietly teaches the next agent that routes are governed and everything else is improvised. The
memory's *shape* is itself a claim about what matters, and an accidental shape makes an accidental
claim.

**Process.**

1. **Procedural lens.** One subagent reads every `how-to-*`, then surveys the code for **recurring
   multi-step jobs that have no how-to** — work done the same way in several places that a fresh
   agent would have to reconstruct from scratch. It reports, per candidate: the job, the real sites,
   the existing how-to it would parallel, and the step sequence *as the code actually does it*.
   > *"`how-to-implement-a-route` is step-by-step. The code also builds X via the Strategy pattern in
   > four places, in the same order each time, and nothing describes it."*
2. **Semantic lens.** A second subagent reads every `concept-*`, `pattern-*`, and `invariant-*`,
   then surveys for **load-bearing vocabulary and rules that aren't named** — a domain term three
   modules depend on with no `concept-`, a convention held everywhere with no `pattern-`, a rule the
   code visibly never breaks with no `invariant-`. It reports the term or rule, the sites, and
   **what an agent would get wrong not knowing it** — that last field is the actual test.
   > *"`concept-*` names the billing period, but the code everywhere treats a lapsed account as
   > distinct from a cancelled one and nothing says so."*
3. **Bring the top 3, one at a time. Do not dump the list.** This move is a conversation and the
   human's reaction is the instrument. Present the evidence — *here's what the code does, here's the
   shard that exists, here's the one that doesn't, here's what I'd write* — and let them respond. A
   rejection is information, not a miss: usually it means the thing is deliberate, or so obvious to
   everyone on the project that only a survey would flag it.
4. **Run each survivor through the gate**, then write it with its routing row in the same commit.

**The validation gate.** Per proposal, in order. **Failing any item means drop it or route it
elsewhere — never argue it into shape.** This is where the move's own principles get enforced
against it:

1. **The ladder (E3).** Could structure carry it? If it says *where* code lives, it's a refactor —
   `harnessability.md`, not a shard. Could a lint carry it? If it's mechanically checkable, the rule
   belongs in `lints.md` and the shard shrinks to the *why* the lint can't state.
2. **Prefix scope.** Only four prefixes are available to a survey: `how-to-` and `concept-` freely;
   **`pattern-` needs cited sites**; `invariant-` needs the code to *visibly* never break it, and
   then gets tested immediately for lint demotion (item 1). **`example-*` is banned here** —
   episodic memory cites a real sha and is never synthetic. **`decision-*` is banned here** —
   direction comes from a human stating it, which is move 6.
   > `expert-structure.md` forbids `pattern-*` on **bootstrap**, and this doesn't contradict it: that
   > rule governs a scan of a single snapshot with nobody in the room. This move produces a **site
   > count** across the whole codebase, and the site count *is* the recurring evidence bootstrap
   > can't have — with a human confirming it.
3. **Routable (E1).** Can you write a `USE WHEN` line naming a **task an agent will be doing**? If
   the honest line is *"when you want to know about X,"* nothing will ever route to it. Then check
   **collision**: if an existing shard's `USE WHEN` already claims that trigger, you've built an
   ambiguity where both or neither open.
4. **Not already there (E6).** If an existing shard covers it, this is an **edit** to that shard or
   a routing fix (move 2) — never a second file. Two shards on one topic is the failure mode this
   move is most likely to cause. And if the fact *is* in the Expert but agents never consult it
   before the decision it governs, that's a missing pointer in `AGENTS.md` (`agents-md.md`), not
   missing memory.
5. **Absence costs something (E7).** Name what a plan gets *wrong* without it. If you can't, it's a
   description of the project, not memory — and descriptions are what the codebase is for. Dropping
   a proposal here is the move working, not failing.
6. **The human said yes.** A survey finding is a candidate, not a fact about what the project needs.

**Produce nothing when** the existing shards already cover the recurring work, or when the only
candidates describe what structure already says. **This is the expected outcome on a well-tended
Expert** — a move that always finds something to add is a move that inflates the routing table.

### 6. Write standing direction

**What it is.** The interview move. The human states where the project is heading; you turn it into
a `decision-*` shard the next planner will treat as a target.

**Why it pays.** This is the only path into the system for intent that isn't in the code yet. Every
other lever describes what *is*. Without this, direction reaches the harness only when the developer
happens to be in the room for that feature — which is the thing this whole framework exists to stop
requiring.

**Process.** No subagent. Ask what they've decided that the code hasn't caught up to, and — the
question that actually surfaces things — *what would you be annoyed to see the next PR do?* Push
until you have the **why**, not just the target; a decision without a rationale can't be applied to
a case it didn't anticipate.

**The fix.** A `decision-<slug>.md` carrying: the direction and why; a `[[concept-…]]` wikilink to
the current state it's departing from; and an **Until fulfilled** note — explicitly what *advances*
the decision versus what stays *consistent with today's code*. **No status field** — the file
existing means adopted. Write the *Until fulfilled* note carefully: `/spec-planning` reads decisions
as forward-looking targets and verifies current state before assuming anything in them exists, so
that note is what keeps a half-migrated codebase coherent.

**Produce nothing when** the human's direction is already realized in code — that's a `concept-` or
`pattern-` fact, not a decision.

### 7. Demote down the ladder

**What it is.** For each shard, ask whether a lower rung could carry it. Prose is the most flexible
rung and the only one that rots; every move down is permanent.

**Why it pays.** A demotion **deletes context instead of adding it**, and the deletion is a
correctness upgrade rather than a token saving — the thing you removed was the thing that could go
stale.

**Process.**

1. **Mechanically checkable `invariant-*` → a lint.** If a rule can be greped or AST-checked, a lint
   can't be sailed past and the harness runs it deterministically. The shard then shrinks to the
   *why* the lint can't state. Rules for doing it properly — message quality, and never
   auto-grandfathering violators — are in `lints.md`; the lint must pass clean against current code
   before it wires in.
2. **Where-without-why shards → structure.** This is the Expert-compensation scan, and it lives in
   `harnessability.md` (option 2) because the fix is usually a rename. **Route the human there
   rather than restating it** — and note the common outcome: the structure is already fine and the
   shard merely restates it, so there's nothing to refactor, just a shard to trim.

**The fix.** Land the lower rung first, then trim or delete the prose — never the other way around,
or there's a window with no rung at all.

**Produce nothing when** the shard carries a real *why*, a judgment call, or direction. Those have
no lower rung — prose is their correct home, and demoting them would lose the thing that mattered.

---

## What keeps a shard honest

Nothing enforces prose. So for each shard you write or keep, say what makes its decay *detectable*:

- **Cite it.** File paths, symbols, shas. A vague shard can't be checked and so can never be found
  wrong; a cited one gets caught by move 3. Citations are what make staleness a diff instead of a
  feeling.
- **Prefer a lower rung where one exists** (move 7). A lint can't rot.
- **Add a Tier-1 eval case.** `evals/expert/` answers a targeted planning question **with vs.
  without** the shard, invoking the real `/expert` — so it tests routing *and* content together.
  That turns "did my edit help?" into a runnable question graded on developer intent, not on the
  shipped code (`evals.md`). A few `evals/spec-planning/` cases cover the real invocation.

**Editing an existing shard?** With/without can't tell you whether the edit *improved* it — both
arms would have a shard. Use version-vs-version (`--prev` / `--prev-from`) instead (`evals.md`).

## What a shard unlocks downstream

Say these to the human — they're why an hour here compounds:

- **Every future spec plan opens with it.** `/spec-planning` consults the Expert before it writes
  anything; the shard you add today is read by features nobody has proposed yet.
- **`/intent` gets sharper input.** It loads the Expert to ground PRD constraints and to choose the
  *shape* of each runner check from what the project already does — so better memory produces a
  better definition of done, not just a better plan.
- **`/learn` gets an anchor.** Its reconcile passes compare the next merge against what's written.
  An accurate shard means the loop can contradict it and correct itself; a missing one means there's
  nothing to reconcile against, and the lesson lands as a new file nobody reviewed against context.

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
  This memory is theirs; an unbidden audit grades it without being asked.
- **Never gatekeep an edit because "the code doesn't show it yet."** Direction, aspiration, and a
  decision made this morning are all legitimate memory — they're the memory nothing else can hold
  (E5).
- **Never retire a `decision-*` on your own initiative.** `/learn` handles fulfilled ones; only a
  human, present, can call one dead.
- **Never append a correction next to a wrong shard.** Edit it or delete it — leaving both means the
  agent picks one at random (E6).
- **Never add a shard without its routing-table row in the same commit.** An unlisted file is
  invisible, and an invisible shard is worse than none: it looks like coverage.
- **Never write a shard that only says where code lives.** That's a bug report against the
  structure, not memory — route it to `harnessability.md` (E3).
- **Never write an unresolving wikilink.** `check-expert-links.sh` fails the PR, and rightly.
- **Never invent an `example-*`.** Episodic memory cites a real sha or it doesn't exist; a synthetic
  example is a fabricated few-shot demonstration.
- **Never add a shard by extrapolation alone.** Every proposal cites real sites and names what a
  plan gets wrong without it. A plausible shard nobody opens is a permanent tax on routing (move 5).
- **Never manufacture a finding.** A healthy Expert, a pending decision, a shard carrying a real
  *why* — each correctly produces nothing (E7).
