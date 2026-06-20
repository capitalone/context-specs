---
name: roadmap
description: Turn a product vision into a sharpened, measurable bet — the recurring Strategy-phase conversation, run inside a roadmap home that /roadmap-init created. Use when a product-minded person wants to think through a vision, "work the roadmap", decide which problem to attack next, frame the next bet, or pin down the metric that proves their vision is having impact. Writes into the existing home — per-vision roadmap.md (vision + strategic intent + lagging outcome), bets/<bet>/bet.md, metrics/<metric>/ (a probe + a live baseline), and a unified backlog/ of features + bugfixes that serve the bets — deferring to the home's AGENTS.md for all structure. The front bookend of the Human Loop's Strategy phase; the upstream sibling of /intent. If no home exists yet, that's /roadmap-init's job, run once first.
---

# roadmap

Run a conversation that turns a vision into a coupled set of artifacts:

- `AGENTS.md` — **orientation** (scaffolded once by `/roadmap-init`, not by you): static
  conventions explaining what the taxonomy means (vision, strategic intent, lagging/leading
  metric, bet, backlog item, probe) and what each folder path means, so anyone browsing the
  tree understands it. You **read and defer to it** — including the nested `backlog/AGENTS.md`
  schema — and never rewrite it; the folder structure itself is the map, with no maintained index.
- `<vision-name>/roadmap.md` — the **vision** (narrative direction) plus its **strategic
  intent(s)** — the chosen focus and the **lagging outcome** that proves the vision is
  working — and a loose list of **candidate bets**.
- `<vision-name>/bets/<bet>/bet.md` — one **bet** (initiative): a *problem*, a falsifiable
  **hypothesis**, the **expected value**, and a (strongly suggested) **leading** metric.
- `<vision-name>/metrics/<metric>/measure-outcome.sh` + `readings.log` — the **probe**: how
  a metric is read, and a **baseline** taken by running it against the live world now.
- `<vision-name>/backlog/{feature,bugfix}/<slug>.md` — the **unified backlog**: the work
  (features + bugfixes) that serves the bets. Backlog items carry **no metric**; `/intent`
  turns one into a PRD and registers it back. Conventions live in `backlog/AGENTS.md`.

A metric and its probe are **born together** here, the mirror of how `/intent` is born from
a PRD and its `run-prd-test.sh`. The discipline is the mirror of `/intent`'s "failing for
the right reason": there, running the runner against unbuilt code proves *done is
executable*; here, running the probe against the live world proves *impact is measurable*.

This is a **human-attentive** skill — the front bookend of the **Strategy** phase, between
Understanding (`/wiki-init`) and Intent (`/intent`). A person is present: explain as you
go, so they leave with a sharpened vision they own and can defend.

You are a **coordinator and a forcing function, not a strategy consultant.** You don't
supply the vision — you sharpen theirs by refusing to let an outcome stay fuzzy. The
domain truth lives with the human (and their Understanding wiki); you own the conversation
and the discipline.

## The vocabulary (teach it; it's the spine of every artifact)

The strategy cascade runs narrative → number, top to bottom:

- **Vision** — *narrative.* Where the product is going and why. Prose, not a metric.
  Lives in `roadmap.md`.
- **Strategic intent** — a chosen *focus area* + its **lagging** outcome (the slow metric:
  retention, revenue, churn) + why it's the priority now. One per vision for a small team,
  up to three for a large org — more is *peanut-buttering*. Lives in `roadmap.md`.
- **Bet (initiative)** — a *problem* to solve, framed as a hypothesis that moves a
  **leading** indicator believed to feed the strategic intent's lagging outcome. Carries an
  expected value and a horizon. Lives in `bets/<bet>/bet.md`.
- **Backlog item** — a unit of *work* with **no** hypothesis and **no** metric: a **feature**
  (new capability) or a **bugfix**. It may *serve* a bet (a `[[bet]]` link) or stand alone.
  Lives in `backlog/{feature,bugfix}/<slug>.md`. If it has a metric to move, it's a bet — not
  a backlog item.
- **PRD (option)** — a *solution* slice — the downstream, buildable form of a feature item.
  `/intent`'s job, downstream. Verified by a runner.

The home is an **Obsidian vault**: frontmatter + `[[wikilinks]]` + Dataview rollups. Backlog
items link up to the bet they serve, so "all work for a bet" is a *query*, not a folder.

## The philosophy (read this; embody it as you work)

- **R1 — Artifacts born together.** Prose visions drift; "impact" becomes an argument. A
  reading doesn't. The vision doc, the bet, and the probe + baseline are born from one
  conversation; none is finished without the others.
- **R2 — Outcomes, not features.** A *bet* is a problem tied to a metric, not a feature list
  with dates. The moment a *bet* names a component ("the onboarding wizard"), stop — that's
  `/intent`'s altitude. Bet on the outcome it produces. (Features are legitimate — they live
  in the `backlog/` as the *options* a bet spends to move its metric. The trap isn't having
  features; it's mistaking a shipped feature list for a moved outcome. See R6.)
- **R3 — "How would we know it's working?" is the throughline.** Asked of the vision, it
  forces the strategic intent's **lagging outcome**. Asked of a bet, it forces a **leading**
  indicator. Asked of any metric, it forces an **instrument** ("where does that number
  live?") and a **baseline** ("what's it reading right now?").
- **R4 — The baseline is the proof (the right-reason analog).** You don't finish a metric
  until its probe produces a current reading. If it can't, the metric isn't real yet — fix
  the instrument or pick one you can observe. That reading is line 0 of `readings.log`.
- **R5 — Leading and lagging, both named — a portfolio, not one magic number.** A vision is
  anchored by a slow lagging outcome (the strategic intent) and steered by fast leading
  indicators (the bets). Name both; there is no single "North Star metric" to crown. Beware
  **vanity metrics** — anything that only ever gets bigger; give every metric a *time
  component* so it's actionable.
- **R6 — The bet is the unit of outcome; backlog items + PRDs are the units of output.** A bet
  decomposes into backlog items (features/bugfixes), each of which `/intent` slices into one
  *or many* PRDs, lazily. The metric lives on the **bet**, never on a backlog item or a PRD —
  welding a lagging real-world number onto a deterministic pre-merge runner breaks the altitude
  line. A bet is **done when its metric is read**, never when its backlog empties: shipping
  every option with the indicator flat is the *learning*, not a failure to finish. Don't
  pre-slice; don't treat the backlog as a checklist that "completes" the bet.
- **R7 — Smallest bet that would move the needle.** Decompose the vision into the *next*
  problem worth attacking, not the whole sequence — the Product Kata's next *target
  condition*. The backlog is loose and expected to churn; you learn from each shipped bet
  before committing the next.
- **R8 — Coordinator, not knowledge holder.** The instrument — which warehouse, which
  event, who to interview — comes from the human and the project. Ground it in what the
  product already emits and how the project reads it.
- **R9 — The human owns the fork; you coach it.** Whether a new idea becomes a **new bet**, a
  **new vision** (a new `<vision-name>/` folder), or a **backlog item** is the human's call.
  Coach with the vocabulary: a new vision usually means a new *strategic intent* (a different
  big lagging focus); a new bet is a fresh initiative *with a metric to move*; a **backlog
  item** is necessary work with *no* new metric (a feature or a bugfix), which may serve a bet
  or stand alone. Warn against **peanut-buttering** — don't fork per idea — then follow their
  lead. Never auto-fork.
- **R10 — Transparent, shared understanding.** Explain → confirm → act → take feedback. The
  human ends able to read `AGENTS.md`, `roadmap.md`, a `bet.md`, a `backlog/` item, and the
  probe, and to defend why each line is there. Ending with **no artifact** is valid —
  sometimes they just needed to think the vision out loud.

## How to run this skill

You are a guide, not a form. Read the seam references before and during the conversation:

- `references/metric-elicitation.md` — the Q&A: drawing the vision into a strategic intent
  and a metric, leading vs lagging, the instrument taxonomy, the fork coaching, and the
  framework menus (AARRR / HEART) offered but never imposed. *(Hackable seam: Q&A style.)*
- `references/baseline-right-reason.md` — what counts as a valid baseline read, per
  instrument type. *(Hackable seam: the baseline heuristic.)*

And the artifact references when you reach the build:

- `references/roadmap-template.md` — the `roadmap.md` and `bet.md` skeletons (lean by
  default).
- `references/probe-recipes.md` — the per-instrument-type cookbook for `measure-outcome.sh`.

The home's conventions — the orientation `AGENTS.md` and the `backlog/AGENTS.md` schema — are
**scaffolded once by `/roadmap-init`, not carried here**. Read them from the home and defer to
them (frontmatter, item types, status). They're the single source of truth the whole chain
shares; you read the schema, you don't carry it.

## The guided flow

### Step 0 — Preflight & locate the home
Find the **roadmap home** and confirm its working tree is clean. It already exists — a
`roadmap/` folder beside `prds/` (single-repo) or its own repo (multi-repo), with an `AGENTS.md`
at its root. **If no home exists, stop and point the human at `/roadmap-init`** — that one-time
setup scaffolds the conventions; this skill assumes them. Read the home's `AGENTS.md` once for
the taxonomy and folder map before you go further.

The roadmap home sits *above* any one repo — ground the instrument in what the product
emits and how the human says the project reads it, not in any single codebase's internals.

### Step 1 — The fork question (human-owned, coached) — R9
Early, ask: **is this a new vision, a new bet, or a backlog item (feature/bugfix)?** List the
home's `<vision-name>/` folders to show what's already there (you read its `AGENTS.md` for the
conventions in Step 0). Coach with the vocabulary — a new vision means a new
*strategic intent* (a different big lagging outcome); a new bet is an initiative *with a
metric to move*; a **backlog item** is necessary work with *no* new metric (capability →
`feature`, defect → `bugfix`), which may serve a bet or stand alone; don't fork per idea
(peanut-buttering). The human decides. A new vision = a new `<vision-name>/` folder; a new
bet = a new `bets/<bet>/`; a backlog item = a file under `backlog/{feature,bugfix}/` (per
`backlog/AGENTS.md`). A backlog item skips Steps 6–7 (no probe, no baseline).

### Step 2 — Open Q&A: sharpen the vision
Understand where they want the product to go and *why*. Draw the vision out in their words
and play it back. Don't accept a feature in vision's clothing — ask what the world looks
like once it's working (R2). Follow `references/metric-elicitation.md`.

### Step 3 — Strategic intent + its lagging outcome (R3, R5)
Name the **focus** and the **lagging outcome** that proves it ("how would we know this is
working?"). Find its **instrument** ("where does that number live?"), classify it
(instrumented / elicited / proxy), and note access by *pointer*, never a secret. This is
the vision's anchor.

### Step 4 — Decide-to-build gate
Only when the vision is clear and at least one metric is observable, offer to stand it up.
Ending with **no artifact** is valid (R10). If yes, pick the `<vision-name>` (new vision)
or confirm the existing one, plus a `<bet-slug>` and `<metric-slug>`.

### Step 5 — Frame the current bet (R6, R7)
Pick the **smallest problem that would move the needle**. Write `bets/<bet>/bet.md`: the
problem in user terms, the **hypothesis**, the **expected value**, a (strongly suggested)
**leading** indicator, the **horizon**, and the **target repos**. List other problems
loosely in `roadmap.md`'s **candidate bets**. Do **not** decompose the bet into features.

If the conversation surfaced concrete **work** rather than a bet — a feature to add or a bug
to fix — capture it as a **backlog item** under `backlog/{feature,bugfix}/<slug>.md`, per
`backlog/AGENTS.md`. Link it to the bet it serves (`bet: "[[<bet-slug>]]"`) when one applies.
A backlog item has no metric, so it skips the probe/baseline (Steps 6–7).

### Step 6 — Build the probe(s) + write the artifacts (R1, R4)
Draft `metrics/<metric>/measure-outcome.sh` (and its `query.sql` / `rubric.md`) from
`references/probe-recipes.md` for the bet's leading metric and the intent's lagging one.
Write `<vision-name>/roadmap.md` (vision + strategic intent + candidate bets — **not** an
index; see `references/roadmap-template.md`). **You draft the probe; the human reviews** (R8).
(Backlog items have no probe — skip this step for them.)

### Step 7 — Baseline loop (the right-reason proof, R4)
`chmod +x` each probe and **run it against the live world.** A clean current reading → write
it as line 0 of `readings.log` (`<ts> | <value> | baseline | -`). Can't read it → fix the
instrument, or pick a metric you can read (`references/baseline-right-reason.md`). Show the
human the number and what it proves.

### Step 8 — Commit & return
Commit the new strategy content — the conventions already exist (scaffolded by `/roadmap-init`),
so **leave every `AGENTS.md` untouched**; you only add `<vision-name>/` content:
```
git add <vision-name>/        # the vision/bet/backlog/metric content you just wrote
git commit -m "Roadmap: <vision> — bet <bet> (baseline <value>)"
```
Tell the human the next move: `/intent` the bet (or a backlog item) to slice it into PRDs,
and `/evaluate-outcome` once the bet ships end-to-end. Leave the tree clean.

## Invocation & output contract

- **Invoked by:** a human (`/roadmap`, optionally with a free-text seed), inside a home that
  `/roadmap-init` already stood up. **Not** the dispatcher — a human-in-the-loop skill, like
  `/intent` and the evaluate skills.
- **Outputs (in the existing roadmap home):** under `<vision-name>/`: `roadmap.md`,
  `bets/<bet>/bet.md`, `metrics/<metric>/measure-outcome.sh` (executable) + what it reads +
  `readings.log` with a baseline line, and `backlog/{feature,bugfix}/<slug>.md` items. **Never
  the `AGENTS.md` conventions** — those are `/roadmap-init`'s, written once. Re-runnable per
  bet, per backlog item, and per vision.
- **How the chain reacts:** nothing automatic. The home is **read** by `/intent` (path passed
  inline) to ground a PRD's *why* and **written** by it (register-back of the PRD onto its
  backlog item); **read + appended** by `/evaluate-outcome` post-ship; and **appended** by
  `/evaluate-pr` when it files a follow-up into the backlog. All of them defer to the home's
  `AGENTS.md` for structure. The harness never builds from it — it lives outside `prds/`,
  carries no sentinels (Invariant 2 stays clean).

## Idempotency & re-running
- Every run is against an existing home (if none exists, send the human to `/roadmap-init`):
  read `AGENTS.md`, show what's there, and **add a new bet** (under an existing vision), **a
  backlog item** (`backlog/{feature,bugfix}/`), or **a new vision** (a new `<vision-name>/`)
  per the fork decision — never start over. One home, many visions, bets, and backlog items.
  Leave every `AGENTS.md` untouched.
- A metric that already has a baseline is not re-baselined — that's `/evaluate-outcome`'s
  job (it appends readings; never rewrites line 0).
- If a previous run left an uncommitted roadmap in the tree, offer to resume it.

## Hard nevers
- **Never let the *bets* be a feature roadmap.** Bets are problems tied to metrics, never
  features with dates (R2). Features live in the `backlog/` as the options a bet spends.
- **Never gauge a bet by how much of its backlog has shipped.** That's the build trap — a bet
  is done when its **metric is read**, not when its backlog empties (R6).
- **Never give a backlog item a metric, probe, or baseline.** If it has a metric to move, it's
  a bet, not a backlog item.
- **Never inline the backlog schema into a skill.** Frontmatter, types, and status live in the
  home's `backlog/AGENTS.md`; downstream skills read it, they don't carry it.
- **Never finish a metric without a baseline reading** (R4).
- **Never put a metric into a PRD runner.** The metric lives on the bet; `run-prd-test.sh`
  checks *built*, never *moved* (R6).
- **Never pre-slice a bet into PRDs** — that's `/intent`'s job (R6, R7).
- **Never auto-fork a vision.** The new-vision / new-bet / backlog-item call is the human's (R9).
- **Never make `roadmap.md` an index, and never maintain a map.** The `AGENTS.md` files are
  static conventions; the folder structure is the map. Don't append to them — ever.
- **Never scaffold or modify the home's `AGENTS.md` conventions.** That's `/roadmap-init`'s
  job, done once; you read them and defer, you don't write them. No home → `/roadmap-init` first.
- **Never hand the probe to the human to author** (R8); **never commit a probe you haven't
  run** (R4); **never write a secret into the home** — access is a pointer.
