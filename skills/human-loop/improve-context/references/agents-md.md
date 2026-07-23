# `AGENTS.md` — the eagerly loaded memory

The context an agent reads whether it needs it or not: what earns a line, and
the moves that keep it earning one.

Every other prose lever is *fetched*. A shard is read if something routes to it; a skill loads if
its trigger fires; the codebase is read if agentic search reaches it. **`AGENTS.md` is different:
it is loaded automatically into every session that enters its folder.** No routing, no trigger, no
search. The agent *will* read it.

That guarantee is the whole product, and you pay for it in a currency no other lever charges: **you
pay for every line in every session, whether or not it's relevant to the task at hand.** A line
here is rent, charged forever, on work that may have nothing to do with it. Which is why this lever
has the highest bar of the six — and why its job is narrow and specific: **the few rules an agent
needs *before* it would think to look anything up.** Everything else is the Expert's (`expert.md`).

**Two kinds of work live here**, and the menu is ordered by them: **taking lines out** — pruning
what fails the bar, converting prose to pointers, deleting what's gone stale (cheap, minutes,
almost entirely deletion) — and **scoping what's left to folders**, which is where the real token
win is, because a rule that only loads where it applies stops taxing every session that will never
need it.

## The principles

- **A1 — Eager rent, charged forever.** Every line is paid in every session that enters the folder,
  relevant or not. No other lever has this property: a bad shard costs nothing until something
  routes to it; a bad `AGENTS.md` line costs on every invocation, forever, starting now.
- **A2 — The guarantee is what you're buying.** A shard *might* be routed to. A skill *might* load.
  A file *might* be reached by search. This *will* be read. That makes it the right home for a very
  small set of facts — the ones where "the agent probably found it" isn't good enough — and the
  wrong home for everything else. **For that small set, this is the best lever there is.** Don't
  under-use it out of frugality; the failure mode runs both ways.
- **A3 — The five predicates — all five must hold.** A fact earns a line only if **every one** is
  true. Most candidates fail at least one:
  1. **Needed before consultation.** The agent must have it *before* it would think to open the
     Expert. If it would naturally route to `/expert` at that decision, the fact belongs in a shard
     and this file just needs a pointer.
  2. **Non-inferable from the code.** If an agent could work it out by reading the tree, don't pay
     eager tokens to say it. Structure carries this for free (`harnessability.md`).
  3. **Harmful if violated** — in behavior or data, not style. Taste doesn't earn eager rent.
  4. **Stable.** A line that changes with the next feature will be wrong before it's read.
  5. **Local-or-truly-global.** Truly global → root. Local to a folder → the nested file (A5).

  **Caps:** root ≤ 150 lines, nested ≤ 80, enforced by `check-agents-md.sh` and tunable via
  `AGENTS_MD_ROOT_CAP` / `AGENTS_MD_NESTED_CAP`. **The cap is a forcing function, not a target** —
  hitting it means something should have been a pointer.
- **A4 — Map, never territory.** `AGENTS.md` points *into* the Expert; it never copies it. A
  pointer stays correct as the Expert grows; a copied paragraph drifts from its source and then
  contradicts it — **and the eager copy is the one that gets read.** If you find prose here that
  restates a shard, that's the defect.
- **A5 — Folder scoping is the token lever.** A root line taxes every session in the repo. The same
  line in `<folder>/AGENTS.md` loads only for agents working there. So: **split when it pays** — a
  nested file is *earned* when root holds rules that are local to a folder, not created because a
  folder exists. The token argument decides, never a folder count. And you can only scope rules as
  well as your folders are scoped: illegible structure forces rules up to root because there's no
  coherent folder to attach them to (`harnessability.md`).
- **A6 — Churn is worse than absence.** A missing rule leaves the agent uncertain, and uncertainty
  prompts a look. **A stale eager rule is read *confidently*** — the agent has no signal it's
  wrong, and no reason to check. A wrong line is worse than no line, which is why staleness (move
  3) is the most dangerous defect this lever has.
- **A7 — Pruning is the expected outcome.** Every line removed is a tax refund on every future
  session — this is the one lever where a *deletion* is measurable. A pass that always adds is a
  pass that manufactures rent. A file that's already tight correctly produces nothing.

## How to guide the user

**Present the menu first. Do not run an audit the human didn't choose** — an unbidden survey grades
a file nobody asked you to grade. Read the five moves with what each improves, let them pick, then
run only that one.

**Be honest about the shape of their file before they choose.** Look first at what exists: how many
`AGENTS.md` files, root vs. nested, and how close each is to its cap. **If the project has one root
file of a hundred-odd lines and no nested ones, say so** — moves 1–3 are a five-minute pass over a
short file, and moves 4 and 5 are where the value is. Don't let them pick an audit with almost
nothing to audit.

**Use subagents to read the actual file and the actual tree, not a hardcoded checklist.** Every
move below dispatches `Explore` agents over the `AGENTS.md` files, the Expert shards, and the
folders the rules are about. Give each a slice and a schema for what to report, run them
concurrently, and synthesize.

| # | Move | What it improves | Typical cost |
|---|---|---|---|
| 1 | **Predicate audit — cold-read every line** | Only lines that earn eager rent survive | Minutes |
| 2 | **Map/territory — prose → pointer** | The file points at the Expert instead of copying it | Minutes |
| 3 | **Staleness audit — does every claim still hold?** | No line is read confidently and wrong | Minutes |
| 4 | **Demote a rule to a nested file** | Local rules stop taxing every session | ~30 min |
| 5 | **Author a new nested `AGENTS.md`** | A folder's agents get what they need before they'd look | ~30 min, careful |

1–3 mostly *delete* — lead with them when the human has no preference; they're cheap and every
result is a refund. 4 relocates rent that's already being paid. **5 is the only move that creates
new rent, and the only one that can leave the project worse — read its warning before offering
it.**

---

### 1. Predicate audit — cold-read every line

**What it is.** Take each line or block as a discrete claim, forget that anyone chose to write it,
and ask the five predicates of it (A3). Keep only what clears all five.

**Why it pays.** This is the highest ratio on the menu, and the outcome is almost always deletion.
Lines accumulate here by a one-way ratchet: `/learn` adds them post-merge, one fact at a time,
each defensible in isolation — and nothing in the system ever proposes taking one out. **You are
the only pass that subtracts.**

**Process.**

1. Have a subagent enumerate every line/block in each `AGENTS.md` as a separate claim.
2. Score each against all five predicates and **name the specific one it fails** — "fails #2,
   inferable from the folder name" is actionable; "seems unnecessary" isn't.
3. Expect the failures to cluster in two places:
   - **#1 (needed before consultation)** — the agent would naturally route to `/expert` at that
     decision anyway. The fact belongs in a shard; this file needs at most a pointer to it.
   - **#2 (non-inferable)** — the tree already says it. Structure carries it for free, and unlike
     prose it can't drift out of sync with itself (`harnessability.md`).
4. Report with the line count that comes back, per file, against the cap. That number is the
   result.

**The fix.** Delete, or convert to a pointer (move 2). A line that fails only #5 isn't a delete —
it's a demote (move 4).

**Produce nothing when** every line clears all five predicates. Say so plainly; a tight file is the
healthy outcome, not a failed audit.

### 2. Map/territory — prose → pointer

**What it is.** Find passages here that restate something the Expert already says, and replace each
with a pointer into the shard that says it.

**Why it pays.** Two copies of a fact don't stay two copies of the same fact. The shard gets
updated by `/learn` on the next merge; the eager paragraph doesn't — and **the eager copy is the
one that gets read** (A4). So the duplication doesn't just cost tokens, it decides which version of
a contradiction wins, and it picks the stale one.

**Process.**

1. Subagent diffs the `AGENTS.md` prose against the Expert shards. Any passage that restates a
   shard's content is the defect; a passage that *names* a shard and says when to open it is
   correct and stays.
2. Check link style while you're in there: `AGENTS.md` uses `[text](path)` markdown links, **never**
   `[[wikilinks]]` — those are internal to `expert/references/` and are validated by a different
   script. A wikilink here resolves for nobody.
3. Prefer the pointer that names the *decision*, not the file — "consult the Expert before choosing
   where new code lives" beats a bare path, because it tells the agent when to follow it.

**The fix.** Replace the paragraph with a pointer. It gets shorter, and it stays correct as the
Expert grows.

**Produce nothing when** every reference is already a pointer and no prose duplicates a shard.

### 3. Staleness audit — does every claim still hold?

**What it is.** Check that the file still describes the project. Two halves, and they need saying
separately because one is free and one isn't.

**Why it pays.** A6: a stale eager rule is read *confidently*. The agent gets a wrong fact, before
it would think to verify anything, with no signal that it's wrong — and it will act on it. This is
the worst failure mode the lever has, and it is entirely invisible until something breaks.

**Process.**

1. **The mechanical half — run the script.** `skills/harness/learn/scripts/check-agents-md.sh`
   checks two things across every `AGENTS.md` in the repo: the line caps, and that **every
   backticked or markdown-linked repo path still resolves** (it skips URLs, anchors, and
   placeholders like `<feature>`, and resolves relative to the file's own directory then the repo
   root). Seconds to run.
   > **Read its output before you act on it — it over-matches.** The path heuristic is a grep for
   > backticked tokens and link targets, so **backticked skill names (`/learn`, `/intent`) and bare
   > filenames get reported as missing paths.** Against the current `survey-ready-app/AGENTS.md`
   > that's 15 findings and all 15 are false. Triage them; don't hand the list to the human as a
   > result, and **never "fix" one by deleting the reference** (see the trap below).
   > **Wiring gap, worth naming to the human:** the script is written to be wired into
   > `local-checks.sh`, and it isn't — `local-checks.sh` globs only `scripts/lints/`, so today only
   > `/learn` invokes this directly. That means dead pointers survive until the next merge. Wiring
   > it in is a category-J lint and takes minutes (`lints.md`, move 7).
2. **The semantic half — the part no script can do.** A path can resolve and the sentence around it
   still be false. Subagent takes every factual assertion in the file — what a folder holds, what a
   command does, what a lint enforces, what the branch flow is — and checks it against the tree,
   the lints, and the Expert. Classify as in `harnessability.md`'s source-of-truth check:
   **all-agree** (most claims, the healthy outcome), **contradicted by the code** (highest
   severity, fix or delete), or **overclaim** — prose broader than the enforcer that backs it, where
   the human picks between narrowing the prose and widening the lint.
3. Weight recent merges. A claim about an area the harness has been actively changing is far more
   likely to be stale than one about a stable corner.

**The fix.** Correct it, or delete it. **Deleting a wrong line beats keeping it** — absence leaves
the agent uncertain, which prompts a look; a wrong line doesn't.

**The trap, and it's specific to this move:** when a reference is broken, the cheap fix is
*deleting the reference* rather than restoring what it pointed to. The check goes green, the file
gets shorter, and what you silenced was **information the agent needed** — not a constraint it had
to obey (`lints.md`, move 7). Ask which one it is before you delete.

**Produce nothing when** the script is green and every claim checks out against the code.

### 4. Demote a rule to a nested file

**What it is.** Find rules sitting at root that are really about one folder, and move them into
that folder's `AGENTS.md`, where they load only for agents working there.

**Why it pays.** It's the cleanest token win on the menu and it costs nothing in coverage: the
agents that need the rule still get it, eagerly, exactly as before. The only thing that changes is
that **every session that was never going to need it stops paying.** Nothing is lost — this is
strictly a refund.

**Process.**

1. For each root rule, ask: **which folder is this actually about?** A rule that names a path, a
   layer, or a subsystem in its own text is usually already answering the question.
2. Estimate what fraction of sessions pay for it and never need it. That fraction is the argument,
   and it's what you take to the human.
3. **Check whether structure is the blocker.** Sometimes a rule is at root because there's no
   coherent folder to attach it to — the concept is spread across three generic directories. Then
   the demotion isn't available yet, and the prerequisite is a legibility refactor
   (`harnessability.md`, move 1). Say that: it's one of the most concrete payoffs that lever has,
   and it's worth naming as *what the refactor unlocks*.
4. Confirm the destination file stays under the 80-line nested cap after the move.

**The fix.** Move the line; run `check-agents-md.sh`; verify the pointer paths still resolve from
the new file's directory (the script resolves relative to the file's own dir, so a working root
path can break on the way down).

**A note on the split posture, because two files in this system disagree and both are right.**
`/learn`'s `agents-md-guidance.md` says *default to fewer files*; the guidance here is *split when
it pays*. Both hold from their own vantage. `/learn` routes **one fact at a time**, post-merge,
without a human — it can't see the aggregate tax, so its conservative default is correct for it.
`/improve-context` reads the **whole file with a human present** and can weigh total rent against
folder cohesion. That's the vantage that earns the split. **Neither licenses creating a nested file
because a folder exists** — the token argument decides.

**Produce nothing when** every root line is genuinely repo-wide. On a project with one root file
and coherent global rules, this is the expected answer.

### 5. Author a new nested `AGENTS.md`

**What it is.** The greenfield question: *would an eagerly loaded file in this folder help — is
there something every agent working here needs before it would think to look anything up?*

**The warning — read this before offering the option.** **This is the only move on the menu that
creates new rent**, and the only one that can leave the project worse. Every line in a new nested
file must clear all five predicates on its own, and it will be paid on every session that enters
that folder from now on. The Expert already covers most of what a folder-specific file would want
to say, lazily, at zero standing cost — which is the right place for it unless the fact fails
predicate #1.

**Producing nothing is the expected outcome most of the time.** A folder that needs nothing gets
nothing. Where move 4 is a refund, this is a purchase.

**The bar a folder must clear:** agents working *in that folder specifically* keep needing a fact
**before** they'd think to consult anything, and it isn't inferable from the code sitting right
there. Both halves matter — "useful context about this folder" is the Expert's job, not this one.

**Process.**

1. Subagent reads one folder and asks: *what does a fresh agent landing here get wrong, and would
   it have known to look it up?* The second clause is the filter; most findings die on it.
2. **Require every proposed line to be grounded in real evidence** — a trace where an agent got it
   wrong, a resolved STUCK, a correction the human has made more than once. **A proposed line with
   no site behind it is speculation, and speculation is exactly how this move makes things worse.**
3. For each surviving candidate, ask the cheaper question first: **is a pointer enough?** A pointer
   into an Expert shard costs one line and can't go stale the way a restated rule can. Usually it
   is. A standalone rule is the answer only when the agent needs the content itself pre-emptively.
4. Draft the file well under the 80-line cap — headroom is the point (A3), not slack to fill.

**The fix.** Write the file, run `check-agents-md.sh`, and tell the human what it will cost per
session in that folder alongside what it buys. That trade is theirs to make, not yours.

**Produce nothing when** the folder's needs are already served lazily, or when the candidate facts
would be discovered by an agent that simply reads the code there.

---

## What holds an `AGENTS.md`

A predicate audit is one person's cold read on one afternoon. Nothing about it is durable — the
next `/learn` run can re-add a line that fails a predicate, and it will be defensible in isolation.
Two things hold parts of this, and neither covers the whole:

- **The mechanical half → `check-agents-md.sh`.** Caps and dead references, deterministically. **Be
  honest about two gaps.** It isn't wired into `local-checks.sh` today — only `/learn` invokes it,
  so a dead pointer survives until the next merge. And its path check **over-matches**: backticked
  skill names and bare filenames read as repo paths, which is why it can't be wired in as a
  *blocking* check as written. Both are fixable and both are category-J work (`lints.md`, move 7) —
  tightening the matcher first, then wiring it in, is the single most durable thing to land off
  this lever.
- **The semantic half → an eval.** `evals/agents-md/<behavior-slug>/`, Tier-1: arm A includes the
  line, arm B strips it, and the criterion is whether the plan **obeys** the rule — not whether it
  quotes it. Because the lever is eager, **pasting the line into the probe is faithful**: there's
  no routing to test, unlike `expert/`, where discovery is half of what's being measured
  (`evals.md`). Be honest that no case exists on disk yet; offer it as the follow-up to a rewrite,
  don't imply it's already protecting anything.
- **Nothing holds prose creep.** Say so out loud. There is no check that a line still deserves its
  rent, and there won't be — predicate #1 isn't mechanical. This lever needs a human pass
  periodically, and that's a legitimate thing to tell them.

## What an `AGENTS.md` improvement unlocks downstream

Say these to the human — they're why a few minutes here compounds:

- **A deletion is measurable.** Every line removed or demoted is tokens refunded on every future
  session, forever. This is the only lever where *subtracting* is the win, and the only one where
  you can quote the saving per session rather than gesture at it.
- **A pointer is what makes lazy memory work at all.** The Expert can be excellent and never get
  opened. Pointers here are the routing layer — improving them raises the value of every shard
  behind them without adding a line of shard content (`expert.md`).
- **Cap headroom is optionality.** A file at 60 of 150 lines can absorb the next genuinely global
  rule `/learn` finds post-merge. A file at 148 forces `/learn` to make a bad choice with no human
  in the room — either it drops a fact that earned its place, or it pushes the file over. **You're
  not just cleaning the file; you're leaving the automated writer room to be right.**

## Before you edit anything — the gate

Every route ends here. Investigation is free; the **first write**
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

- **Never run an audit the human didn't choose.** Present the menu, take their pick, run that one.
- **Never copy the Expert into this file.** Point at it. A copied paragraph drifts from its source,
  and the eager copy is the one that gets read (A4).
- **Never add a line that fails a predicate, however true it is.** Truth isn't the bar — *needed
  before consultation* is. A true, useful, non-urgent fact is a shard (A3).
- **Never leave a stale claim standing.** Deleting a wrong line beats keeping it: absence prompts a
  look, a wrong line is read confidently (A6).
- **Never delete a broken reference instead of restoring what it pointed to.** That silences
  information the agent needed, and hides the rot behind a green check (move 3).
- **Never author a nested file to be thorough.** A folder that needs nothing gets nothing; move 5
  buys rent and most folders shouldn't (A7).
- **Never exceed a cap to fit one more rule.** Over cap means something in the file should have
  been a pointer. Raising `AGENTS_MD_ROOT_CAP` is not a fix (A3).

**Note:** the five predicates are also stated in `/learn`'s `references/routing-rules.md`, which is
the authority when `/learn` routes a fact post-merge — same test, two readers. Its companion
`references/agents-md-guidance.md` defaults to *fewer files* where A5 says *split when it pays*;
that tension is real and resolved in move 4, in favor of neither by default — the token argument
decides.
