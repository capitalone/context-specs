# Harnessability — the codebase as a context lever

**Hackable seam.** This is how you read a codebase *as context* and improve it. A project can
add its own probes, its own grab-bag names, its own work types.

Every other lever is an artifact **about** the code. This one is the code. It is the
highest-volume context any agent reads, and the only context that **cannot lie**: a folder
named `auth/` containing only auth *is* that claim, and it can't drift out of sync with
itself. Prose can rot. Structure can't self-contradict.

**Harnessability** is the property you're improving: how amenable the codebase is to an agent
reasoning about it directly — from names, structure, and neighbors, without asking a person
and without reading everything.

## The ladder — prose → structure → lint

Three ways to carry a fact, in increasing durability:

| Rung | Durability | Cost | Reach |
|---|---|---|---|
| **Prose** (a shard, an AGENTS.md line) | Can rot; may not be read | Tokens, every session | Anything |
| **Structure** (a name, a folder, a file's home) | Can't self-contradict; **decays** as new code lands | **Free** — the agent sees it regardless | Where things go, what gets copied |
| **Lint** | Cannot be violated | Free after authoring | Mechanically checkable only |

**Every move is downhill.** Prose → structure wherever the code can carry the fact; structure →
lint wherever the property is mechanical. The corollary that makes this pay:

> **A shard that describes structure is a bug report against the structure.**

A shard reading *"auth helpers live in `utils/auth.ts`; date code is also in `utils/`"* exists
to compensate for a folder that doesn't say what it holds. Split `utils/` into `auth/` and
`dates/` and the shard becomes unnecessary. **This is the rare improvement that deletes context
instead of adding it** — and the deletion is a correctness upgrade, not just a token saving,
because the thing you deleted was the thing that could go stale.

**Why the agent's shape matters here.** Code reaches the agent by **agentic search** — grep and
glob, not an index. So you can't prune it like an AGENTS.md line or route to it like a shard.
The only knob is: **how far does an agent search before it finds the right thing, and is the
first thing it finds the one you'd want copied?** Agents imitate their nearest neighbor. The
job is to make the nearest neighbor the right neighbor.

## This is horizontal work, never feature work

The rest of the framework forbids agents to refactor (`/fix-local-checks`, `/address-feedback`:
"Never refactor or add features"). That prohibition stands — it stops an agent mid-task from
wandering off its spec. **This is a different thing.** Here the human is present, the refactor
*is* the task, and it changes no behavior.

- **Features go through the harness.** A PRD, a runner, an autonomous build.
- **Harnessability refactors go through you and the human.** They steer *future* agents by
  making the visible thing comprehensible. No behavior change — if it changes what the product
  does, it's a PRD and it belongs to the harness.

**The human is not here to do the cleaning.** They're here to understand how they're steering.
Deciding what's canonical is judgment only they have, and understanding it is the point of
their presence — the refactor is downstream of the decision. This is why volume stays low and
why this doesn't become someone's Friday-afternoon cleanup shift.

---

# The probe menu

Read cheapest-first. Present findings, let the human pick a direction — **and if the codebase is
legible, say so and produce nothing** (C7). A probe menu that always finds something is a probe
menu that manufactures findings.

## Free / mechanical — run these on every survey

No tokens, seconds to run. These are what put a real health read on the codebase row.

**The grab-bag scan.** Grep the tree for `utils/`, `helpers/`, `common/`, `shared/`, `lib/`,
`misc/`. These are names that mean *"I didn't decide."* A folder whose name predicts nothing
teaches nothing — and it accretes, because it's the path of least resistance for every future
agent. Report what's actually inside: *"`src/utils/` holds 11 files spanning auth, date
formatting, and HTTP retry — three purposes, one name."* Three purposes is a split candidate.

**The Expert-compensation scan.** Read the Expert's shards and ask of each: *does this exist only
to explain where things live, or what a name really means?* Prose that maps the tree
(`db/` — all database access; `client.ts` — the client) is the tell. **Then check the structure it
describes, because there are two outcomes and only one is a refactor:**

- **The name is lying** → the shard is a *receipt* for illegible structure; the developer paid
  tokens to work around a name. Refactor, then delete the shard.
- **The name is already fine and the shard just restates it** → this is the common case, and
  there's **nothing to refactor**. The structure already carries the fact; the prose is a
  duplicate that costs tokens and can now drift out of sync with a tree that can't. **Just trim
  the shard.** A free win — don't manufacture a refactor to justify the finding.

Either way the deletion is real, which is what makes this the highest-value probe you have.

**Distinguish honestly — most shards near structure are legitimate.** A shard carrying *why* the
boundary exists, what breaks if you cross it, or where it's heading is doing work structure can't,
and it stays. The model to keep in mind:

> `invariant-db-layer-boundary`: states the rule, explains **why** (one seam, so a future
> migration isn't a repo-wide hunt), and names the lint that enforces it. Prose for the why,
> structure for the where, lint for the teeth. **All three rungs, each doing only its own job.**
> That shard is not debt — it's the ladder working.

Only the *where*-without-*why* half is debt.

**The overclaim scan.** For each shard or `AGENTS.md` line that states a rule an enforcer backs,
check the enforcer's **actual scope** against the prose's claim. They drift apart silently, and
always in one direction: the prose is broader.

> Real example: a shard reads *"No file in `app/` **(or elsewhere)** imports `drizzle-orm`
> directly."* The lint that enforces it greps `app/` and nothing else. Everything outside `app/`
> is unguarded — and a file was already sitting in the gap.

This is rung-1 overclaiming against rung-3, and it's the worst failure on the ladder: the agent
reads a rule, believes it's universal, and nothing catches it when it isn't. Both fixes are
cheap — **narrow the prose to what's enforced**, or **widen the lint to what's claimed** — but the
human picks, because that's a decision about the invariant, not a typo. Cheap to run: read the
lint's scope, read the shard's claim, compare.

**Variant counting.** Pick the project's recurring work types (add an endpoint, add a query, add
a background job — read them off the Expert or recent PRDs). For each, find every existing
instance and count the distinct ways it's done. **N > 1 means the next agent picks by coin
flip.** Weight this by what the harness actually did recently: if your Expert says `routes/` and
the last two PRs used `handlers/`, the harness is drifting away from stated intent right now —
that's the most urgent finding the menu can produce.

## Cheap LLM probes — on request

**The name→content probe.** Show an agent **only the folder tree** — no file contents — and ask
it to predict what lives in each folder and what may import what. Diff its answer against
reality. **Where it guesses wrong, the name is lying.**

This is the measurement. Harnessability is otherwise a thing you can only *feel*; this makes it a
diff. It's also faithful: predicting-from-names is exactly what an agent does before it opens
anything. And it's nearly free — one tree listing, one call.

**The cold-navigation probe.** Drop an agent in the repo with **no Expert and no AGENTS.md** and
one question: *"where would you add a rate limiter?"* If it can't land in the right place from
the code alone, the code alone isn't teaching. Strip the prose deliberately — you're testing what
the structure carries by itself. (This is also the natural before/after check on any refactor.)

**The nearest-neighbor trap.** For the place new code would land, is the **closest** existing
example the one you'd want copied? Deprecated-but-canonical-looking code is the deadliest thing
in an agent codebase: it reads as an exemplar and the agent has no way to know it's dead. Two
things that look canonical where one is abandoned is worse than no example at all.

## From the trail (route (a), free)

You're already reading traces at a STUCK. The navigation lens
(`stuck-forensics.md`) asks the harnessability question of the same evidence: *what did the agent
have to search for that a name should have told it?* Repeated greps for one concept, the wrong
file opened first, a convention re-derived from scratch.

---

# The refactor tiers

Ask the human which rung they have appetite for **today**. Most days it's A.

**Tier A — minutes.** Rename a thing to what it is. Move a file into the folder its name already
implies. Delete a dead exemplar. Split a grab-bag. Highest ratio in the menu: near-zero risk,
immediate effect on every future search.

**Tier B — an hour.** Consolidate N variants onto one. Migrate or delete the losers. The decision
("which is canonical?") is the human's and takes a minute; the migration is the hour.

**Tier C — rare.** Establish a canonical pattern, its exemplar, and the lint that holds it. Not a
weekly move. Reach for it when variant counting keeps surfacing the same split and the human
wants it settled permanently.

## Every refactor lands with an enforcer

**Without one, the harness re-introduces the drift within a week and the session bought nothing.**
The harness is the entropy source: every autonomous PR nudges toward one more variant, one more
file in `utils/`. Legibility decays *proportionally to how well your harness is working*.

- **Mechanically checkable → a lint.** This is the destination. Message quality is not optional
  (`env-init/references/local-checks-design.md` — WHERE / WHAT / WHY / FIX / DON'T-CHEAT); a lint
  whose message doesn't read as a fix-prompt manufactures STUCKs.
- **Not mechanical → name the drift risk out loud** and let the human decide knowingly. Don't
  pretend a refactor is safe when nothing holds it. "This will drift back; nothing enforces it" is
  a legitimate thing to land, *said*.

**The sequencing — the lint is the completeness check.** A lint must pass against current code
before it wires in, and must never auto-grandfather violators (*95% hold + 5% violate = a
migration, not an invariant* — `local-checks-design.md`). So the migration completes **first**, and
a green lint is the proof it did.

This self-limits scope mechanically, which is the point: **you can't take on a migration you can't
finish, because you won't get your enforcer.** Let that cap the work rather than arguing about it.

## What a refactor unlocks downstream

Say these to the human — they're why the 30 minutes compounds:

- **A shard gets deleted or demoted.** The geography shard becomes unnecessary, or stops
  describing where things are and starts pointing at the canonical exemplar. Shorter, and it can
  no longer be wrong.
- **A global rule can become a local one.** You can only scope rules as well as your folders are
  scoped. Illegible structure forces rules up into eager, global `AGENTS.md`, where every line
  taxes every session. Fix the folder and the rule can move into a nested `AGENTS.md` that only
  loads when an agent goes there.
- **The lint holds it forever**, for free, on every future PR.

---

# The anti-pattern: don't write `patterns.md`

The tempting move — inventory the codebase's patterns into a document — is the way-station, not
the destination. **A pattern doc is a shard describing structure**, and the ladder says that's a
bug report against the structure. It will drift from the code the day after you write it, and the
agent will keep pattern-matching against its neighbors anyway, because that's cheaper than
reading your doc.

Consolidate the code onto one pattern and let the **exemplar be the doc**. If a fact genuinely
can't live in the structure — *why* this boundary exists, what direction it's moving — that's the
Expert's job, and it's a `concept-` or `decision-` shard, not a catalog.

# When to produce nothing

- The structure is legible. Names predict contents, one way to do each job, no grab-bags. Say so
  and move to another lever.
- The finding is **taste**, not a legibility defect. "I'd have named it differently" is not a
  probe finding. A refactor needs a named defect behind it — a lying name, a counted variant, a
  geography shard — or it's churn.
- The inconsistency is **real but load-bearing** — two ways to do a thing because there genuinely
  are two cases. Name the distinction; consider whether the *names* should carry it.
