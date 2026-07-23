# Lints — the memory an agent cannot ship past

The bottom rung of the ladder: what earns a lint, why the message is the lever, and
the moves that improve the ones you have.

Every other lever *asks*. Prose asks and can be crowded out of a context window; structure asks and
can be misread. **A lint decides.** `scripts/local-checks.sh` runs everything in `scripts/lints/`
on every check pass, and the harness invokes it deterministically — an agent cannot argue with it,
skip it, or fail to notice it. That is the whole value: it is the only context form that cannot be
ignored.

It buys that with a hard limit. A lint reaches only what is **mechanically checkable** — layer
direction, parse-at-boundaries, naming, canonical placement, skip-detection. It cannot carry *why*
a boundary exists or where you're heading; that's the Expert's job (`expert.md`). The ladder is
**prose → structure → lint**, and this is the destination for anything that can make the trip.

**Two kinds of work live here**, and the menu is ordered by them: improving the lints you already
have (cheap, minutes, mostly message work) and finding the *classes* of invariant nobody has
checked yet (an hour, and where the real headroom is — `scripts/lints/` currently holds one lint).

## The principles

- **L1 — The last rung, and the only one with teeth.** Prose rots and costs tokens every session;
  structure decays as new code lands; a lint holds forever, for free, on every future PR. Anything
  mechanically checkable should end up here. **Every move down the ladder is downhill.**
- **L2 — The error message *is* the prompt, not a diagnostic.** **This is the part people get
  wrong.** On failure the message is *all* a cold `/fix-local-checks` agent gets — no
  conversation, no Expert, no history. Just the message and the files it names. It must carry
  **WHERE / WHAT / WHY / FIX / DON'T-CHEAT**. A terse "rule violated" leaves the fixing agent
  guessing, burns attempts, and **manufactures STUCKs** — the lint becomes the thing that stops the
  build rather than the thing that guides it.
- **L3 — Only the mechanical descends here.** If pass/fail needs taste, it stays prose. The litmus:
  *could two engineers disagree about whether a given file violates it?* If yes, it's Expert or
  `AGENTS.md` work, not a lint.
- **L4 — Recurrence earns a lint.** One sighting is a pattern; repetition is an invariant. You've
  corrected the same thing twice and you're tired of saying it.
- **L5 — It must pass clean against current code, and never auto-grandfather.** This is `/intent`'s
  right-reason check, inverted: a real invariant passes clean today. One that reddens existing
  files isn't an invariant yet — it's a migration. 95% hold + 5% violate = surface the violators;
  never silently baseline them. The migration lands first, and **the green lint is the proof it
  finished** (`harnessability.md`).
- **L6 — Block vs. warn is decided-invariant vs. undecided-taste**, not correctness vs. legibility.
  Layer-direction is a legibility rule and it *blocks* — because someone decided it. Blocking on a
  rule nobody chose burns attempts over a preference
  (`env-init/references/local-checks-design.md`).
- **L7 — The match is a proxy, and every category has a silencing trap.** The pattern a lint
  matches is a *heuristic* for the problem, not its definition. Design it so the cheap way to
  satisfy it is also the *right* way — and name the trap in the message, because the trap is
  whatever satisfies the rule's **match** without addressing its **intent**.
- **L8 — Push fix execution down; spend agent tokens on judgment.** The workhorse resolution path
  isn't silent autofix or agent-only — it's **deterministic-fix, agent-triggered**: deterministic
  code is the transformer, the agent is the trigger and reviewer. An agent should never spend a
  token on formatting.
- **L9 — Producing nothing is a correct outcome.** Healthy messages, an invariant that isn't
  mechanical, a rule nobody has decided — each correctly produces no lint. A sweep that always
  finds something is a sweep that manufactures findings.

## How to guide the user

**Present the menu first. Do not run an audit the human didn't choose** — an unbidden survey grades
a gate nobody asked you to grade. Read the seven moves with what each improves, let them pick, then
run only that one.

**Use subagents to read the actual gate, not a hardcoded checklist.** Every move below dispatches
`Explore` agents over `scripts/local-checks.sh` and `scripts/lints/`. Be honest with the human
about the shape of their gate before they choose: **if `scripts/lints/` holds one or two lints,
moves 1–3 are a five-minute pass and moves 4–7 are where the value is.** Say that rather than
letting them pick an audit with almost nothing to audit.

| # | Move | What it improves | Typical cost |
|---|---|---|---|
| 1 | **Message audit — read every message cold** | Existing lints read as fix-prompts, not stoppers | Minutes |
| 2 | **Gameability audit (match-as-proxy)** | The cheap way to satisfy each lint is the right way | Minutes |
| 3 | **Block/warn + fix-path tuning** | No STUCKs over preferences; no tokens on autofixables | Minutes |
| 4 | **Promote a recurring correction to a lint** | What you've said twice stops needing saying | ~30 min |
| 5 | **Close an overclaim — widen the lint to the prose** | The rule's teeth match its claim | Migration |
| 6 | **Category sweep — find the missing *kind* of lint** | Invariant classes nobody thought to check | An hour |
| 7 | **Lint the harness itself (category J)** | The context files the harness reads are validated | An hour |

1–3 improve what exists and mostly *edit messages* — lead with them when the gate already has
lints and the human has no preference. 4 and 5 add or widen a rule. 6 and 7 are discovery, and 7 is
the one most projects have never done.

---

### 1. Message audit — read every message cold

**What it is.** Take each lint's failure message, strip away everything you know about the repo,
and ask: *could I make the right fix from this alone?* That is the exact position
`/fix-local-checks` is in.

**Why it pays.** A message defect and a rule defect look identical from the outside — both show up
as an agent burning attempts against a red gate. But they have opposite fixes, and the message one
is minutes of work. This is the highest ratio on the menu.

**Process.**

1. Have a subagent extract every failure message emitted by `scripts/lints/*.sh` and by the custom
   legs of `local-checks.sh`.
2. Score each against the five fields, naming which are missing:
   - **WHERE** — file:line, or the offending pattern for a whole-repo rule.
   - **WHAT** — the violation as a fact about *this* code, not the rule in the abstract.
   - **WHY** — one clause. Without it the agent satisfies the letter and breaks the intent.
   - **FIX** — the concrete change (a short menu if several are valid).
   - **DON'T-CHEAT** — name the silencing trap for *this* rule (move 2 finds it).
3. For the ones that fail, rewrite. Template and worked examples:
   `env-init/references/local-checks-design.md`.

**The seven-field superset.** `linter-categories.md` extends the five with **rule identity** (a
stable ID a waiver or triage system can reference), **escape hatch** (whether the rule may be
waived and what obligation comes with waiving), and **fix-applied flag** (if the linter already
autofixed, say so — the agent's job becomes *verify*, not *redo*). Treat these as an upgrade for
rules that need them, not a new requirement for all five-field messages that already work.

**Produce nothing when** every message already carries the five fields. Say so and offer another
move.

### 2. Gameability audit (match-as-proxy)

**What it is.** For each lint, ask the adversarial question: **what is the cheapest edit that turns
this red to green without fixing anything?** That edit is the rule's silencing trap, and if the
message doesn't name it, a cold agent under attempt pressure will find it.

**Why it pays.** A gameable lint is worse than no lint: it reports green, the human trusts the
gate, and the invariant is gone. `skip-detection` exists precisely because "all tests pass" is
gameable — a skipped test is green — so it guards test *removal*, the thing a plain pass check
would reward.

**Process.** Walk each lint against the known traps by category. This table is the prompt, not a
checklist — the trap for *your* rule may not be listed:

| Cat | Trap |
|---|---|
| A Formatting | none — the only category without one |
| B Lexical | semantically-wrong autofix; alias the banned name |
| C AST single-file | `void` the promise (or the analog for your rule) |
| D Dependency direction | widen the allow-list; route through a permitted intermediary |
| E Naming / placement | `eslint-disable` the placement rule |
| F Type / contract | `!` / `as any` / `@ts-ignore` / weaken tsconfig strictness |
| G Grep-ability | suppress the comment — "it isn't a present-tense bug" |
| H Security | hand-rolled escape; fixes locally but the taint propagates |
| I Test invariants | tests that assert the implementation, not the behavior |
| J Harness config | silence the reference instead of restoring what it pointed to |
| K Logging | delete the log; drop the inconvenient field; log everything |

**The fix.** Two options, and they compose:

- **Name the trap in the message** (the DON'T-CHEAT field) — the single most repeatable move here.
- **Add a companion guard** when the gap between match and intent is wide (D, H, K especially).
  Skip-detection is the worked example of a companion guard.

**Re-verify after the fix.** For any rule where the match is a proxy, re-run it against the new
code. If it still matches, the fix was fake.

**Produce nothing when** every message names its trap and no cheap silencing edit exists.

### 3. Block/warn + fix-path tuning

**What it is.** Two questions per lint, both about *disposition* rather than the rule itself.

**(a) Did someone decide this, or is it taste?** The discriminator is **decided invariant vs.
undecided taste** — not correctness vs. legibility. A blocking rule nobody chose manufactures
STUCKs over a preference; demote it to warn until someone owns it.

| Mode | What | Examples |
|---|---|---|
| **Block** | Decided invariants — correctness, or structure the project settled on | Lint errors, typecheck, fast tests, skip-detection, layer-direction, parse-at-boundary, no SQLi/unsafe-cast, placement rules the human opted into |
| **Warn** | Undecided taste — real patterns nobody has settled | Grep-ability, ambient naming habits, log shape |
| **Sensor (not in this gate)** | Test fitness | Mutation testing — async/nightly only |

**(b) Is the fix unique and semantics-preserving?** Then it belongs in `./scripts/local-checks.sh
fix`, which the dispatcher runs at attempt-0 before any agent. Every autofixable rule left on the
agent's plate is tokens spent on a transformation a script could have done (L8). Three paths:

- **Autofixable + safe** → wire into `fix`; the agent never sees it.
- **Needs judgment** (several valid fixes, or the choice is semantic) → no autofix; the message
  must carry enough for `/fix-local-checks` to choose well.
- **Detect-only** → still ship it; expect `/fix-local-checks`, or a STUCK.

**Produce nothing when** every rule blocks on something decided and every safe autofix is already
wired.

### 4. Promote a recurring correction to a lint

**What it is.** Turn something you keep saying into something you never say again.

**Where candidates come from.** Not a scan — your own history:

- A correction you've made **twice** (L4).
- A class of thing PR review keeps flagging round after round.
- **A structural invariant just decided in a `harnessability.md` refactor** — this is the most
  common source, and the lint is what turns that refactor from a cleanup into a ratchet. Without
  it, the harness re-introduces the drift within a week.
- A resolved STUCK whose root cause turned out to be mechanical (`stuck-forensics.md`).

**The three gates, in order.**

1. **Recurrence** (L4) — one sighting isn't an invariant.
2. **Mechanically checkable** (L3) — could two engineers disagree? Then it's Expert work.
3. **Must pass against current code** (L5) — draft it, run it against the repo *before* wiring it
   in. Clean = a real invariant. Red = a migration wearing a rule's clothes. **Never
   auto-grandfather the violators**; surface them and let the human decide whether to clean first.

Gate 3 is also a useful scope limiter: **you can't take on a migration you can't finish, because
you won't get your enforcer.**

**The fix.** Write the lint into `scripts/lints/<name>.sh` — `local-checks.sh` discovers it via
`compgen`, so there's no wiring to change. Write the message *first* (move 1's five fields), then
the matcher. Set its disposition per move 3.

**Produce nothing when** the thing you're tired of saying isn't mechanical. That's a real answer —
write it to the Expert instead and say why it can't descend.

### 5. Close an overclaim — widen the lint to the prose

**What it is.** The lint-side half of `harnessability.md`'s source-of-truth integrity check. Prose
cites an enforcer; the enforcer's actual scope is narrower than the claim. They always drift in
that one direction.

> Real example: a shard reads *"No file in `app/` **(or elsewhere)** imports `drizzle-orm`
> directly."* The lint that enforces it greps `app/` and nothing else. Everything outside `app/` is
> unguarded — and a file was already sitting in the gap.

**Why it pays.** This is the worst failure the ladder has: the agent reads a rule, believes it's
universal, and nothing catches it when it isn't. Silent, confident, wrong. And it's cheap to detect
— read the lint's match scope, read the claim, compare.

**Process.** For each prose rule that names a lint, extract the lint's real match scope (the grep
path, the glob, the file set) and diff it against what the prose claims. Then run the *widened*
matcher to count what's sitting in the gap.

**The fix — the human picks**, because it's a decision about the invariant, not a typo:

- **Narrow the prose** to exactly what's enforced — usually right when the gap is deliberate.
- **Widen the lint** to what's claimed — which means **fixing the violators in the gap first**
  (L5). That's a migration; scope it before agreeing to it.

**Produce nothing when** every enforcer's scope matches its claim.

### 6. Category sweep — find the missing *kind* of lint

**What it is.** Not "are these lints good" but "**what class of invariant is nobody checking?**"
Most gates check one or two categories and have never considered the other nine.

**Read `linter-categories.md` before running this.** The condensed map:

| Cat | Mechanism | Catches |
|---|---|---|
| **A** Formatting & style | AST re-print, total + idempotent | Layout, quotes, import order — deterministic autofix, full stop |
| **B** Lexical / textual | regex, ideally anchored to an AST slot | Banned imports and globals, secrets, `any`, leftover debug, `TODO` without ticket |
| **C** AST single-file | AST visitor, syntactic or type-aware | Banned constructs, floating promises, complexity caps, hook placement |
| **D** Dependency direction | whole-repo import graph | Layer violations, cycles, transitive leaks — catches *indirect* violations through chains |
| **E** Naming & placement | filesystem + AST | Filename↔symbol agreement, prefix conventions, canonical placement, size caps |
| **F** Type / contract | type checker + runtime schema, ingested as messages | Unsafe casts, unparsed boundaries — the cascade *is* the agent's task list |
| **G** Grep-ability | C/B/D mechanisms, distinguished by *rationale* | Anonymous default exports, barrel discipline — "does removing it make the program wrong, or just harder to navigate?" |
| **H** Security / SAST | syntactic → taint/dataflow → pattern + LLM triage | SQLi, XSS, path traversal, secrets; IDOR and access control only with triage |
| **I** Test invariants | dynamic — coverage, structure, mutation | Untested new code, missing test files, tests that assert nothing |
| **J** Harness config | filesystem existence, schema, cross-reference | Dead references in context docs, phantom scripts, platform limits — see move 7 |
| **K** Logging / observability | B/C/D/E mechanisms, one intent | Unstructured logs, missing correlation IDs, stray `console.log`, logged PII |

**Process.**

1. **Fan out one subagent per category slice** over the project's *actual* detected surface. No DB
   → no SQL lint. No logger convention → K is premature.
2. **Every proposal must come back with three things:** a **real site** in this repo (a proposal
   with no site behind it is speculation), a **must-pass-current-main result** (L5), and a
   **block-or-warn disposition** — which the *human* decides, per move 3.
3. **Present as a menu; the human opts in per lint.** Propose, never apply.

**Guard against volume-by-checklist.** Don't ship "40 lints every Next.js app should have." The
right checks are better than more checks, and each one you add is a thing that can manufacture a
STUCK. **Producing two proposals from an eleven-category sweep is a good outcome.**

**Note the delayed-cost cluster (G, J, K).** Their beneficiary isn't the agent now — it's a future
reader, the harness itself, or an operator at 3am. They produce *silent* failures at edit time: no
build error, no test failure, no crash. Agents rationally deprioritize them. **So their WHY field
has to work harder**, or suppression becomes the default move.

### 7. Lint the harness itself (category J)

**What it is.** The meta-move: lints that check the **context files the harness reads**, not the
application code. Does every Expert shard reference resolve? Does `AGENTS.md` cite a file that was
deleted? Does prose naming a lint match a lint that exists? Do `evals/` cases point at live
fixtures?

**Why it pays — and why it's on this menu specifically.** J is the smallest category in scope and
possibly the highest in leverage: **if J fails, every other category's signal becomes unreliable**,
because the harness's own machinery is misconfigured. More to the point for `/improve-context`:
this is what makes the **overclaim failure from move 5 mechanically detectable**. A rung-1 claim
that has silently stopped matching rung 3 is exactly a dead cross-reference — and a J lint catches
it on every PR instead of the next time someone happens to look.

It also has the cleanest profile on the list: **J never runs anyone's code, never reasons about
runtime behavior, never needs the type checker.** Lowest false-positive rate of any category — the
facts it checks are unambiguous.

**Process.**

1. **Inventory what the harness reads:** the Expert shards, `AGENTS.md` (every level),
   `prds/<f>/prd.md`, skill and agent frontmatter, `evals/` case definitions.
2. **Three mechanisms, cheapest first:** existence (`test -f` on every referenced path), schema
   (frontmatter parses, required fields present), cross-reference (a named script exists in
   `package.json`; a named lint exists in `scripts/lints/`).
3. **Add platform limits** — entry files over the context-window character limit, files over the
   read limit. These are footguns most teams don't know exist until an agent silently reads half a
   file.

**Two things J messages need that no other category's do.**

- **A `HARNESS IMPACT` field** — say *what the agent will fail to know or do* because of this
  misconfiguration. No other rule's output has the agent as its subject.
- **Session-start timing.** Pre-commit is the wrong slot alone; a broken reference degrades the
  agent's mental model at the moment it costs the most. Run J when the session opens.

**Its silencing trap is structurally different** — and worth calling out to the human. Every other
trap satisfies a constraint without respecting it. J's trap is **deleting the broken reference
instead of restoring what it pointed to**: the rule passes, the harness has decayed, and the rot is
now hidden. What got silenced was *information the agent needed*, not a constraint it had to obey.
**Second trap: loosening J's own validation** — there is no outer harness to catch that, so treat
edits to J rules with extra scrutiny.

**J validates form, not meaning.** `AGENTS.md` can parse cleanly, resolve every reference, and
still be terrible advice. That half is the eval suite's job, not a lint's.

---

## What holds a lint's quality

A message audit (move 1) is one person's cold read on one afternoon. It doesn't hold — the next
edit to the rule can quietly undo it, and nothing notices.

**An eval freezes it.** `evals/lints/<lint-name>/` feeds **only the message** (plus a fixture) to a
cold `claude -p` — exactly what `/fix-local-checks` gets — and judges whether it produced the right
fix *without silencing*. **A FAIL means the message needs work, not that the rule is wrong**;
that's the whole distinction moves 1 and 2 turn on, made measurable. Layout, rubric, and the
report-driven handoff: `evals.md`.

Be honest that this is the *specified* state, not the built one — no `evals/lints/` case exists on
disk yet. Offer it as the durable follow-up to a message rewrite; don't imply it's already
protecting anything.

## What a lint unlocks downstream

Say these to the human — they're why writing one compounds:

- **A shard can shrink to just its *why*.** Once the lint carries the *where* and the teeth, the
  prose stops restating the rule and keeps only what structure and matchers can't hold. Shorter,
  and it can no longer be wrong (`harnessability.md`, `expert.md`).
- **A legibility refactor becomes a ratchet.** Without a lint, the harness re-introduces the drift
  it just cleaned up — every autonomous PR nudges back toward one more variant.
- **The reviewer stops paying for it.** The PR reviewer costs model tokens per round. Anything the
  deterministic floor catches is a round the inferential layer doesn't spend — which is the point
  of pushing everything mechanizable down.

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
- **Never land a lint that doesn't pass against current code**, and **never auto-grandfather**
  violators. A rule that reddens existing files is a migration; surface the violators and let the
  human scope it (L5).
- **Never block on a rule nobody decided.** Undecided taste warns or doesn't ship — blocking on a
  preference manufactures STUCKs and burns attempts (L6).
- **Never ship a message a cold agent couldn't act on.** No WHY, no FIX, no named trap = a message
  defect that will read as a rule defect forever (L2).
- **Never lint what isn't mechanical.** If pass/fail needs taste, it's Expert or `AGENTS.md` work.
  Saying so is a finding, not a failure (L3, L9).
- **Never add a dedicated anti-cheat lint.** No `no-suppressions` rule. The guard against silencing
  lives in each lint's own DON'T-CHEAT line and in the `/fix-local-checks` prompt; the human and
  the reviewer are the backstops (`env-init/references/local-checks-design.md`).
- **Never chase volume.** Two good proposals from an eleven-category sweep beats eleven mediocre
  ones. More checks is not better; the right checks are (L9).
