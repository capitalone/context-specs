---
name: roadmap
description: Turn a product vision into a sharpened, measurable bet. Use when a product-minded person wants to think through a vision, "build a roadmap", decide which problem to attack next, or pin down the metric that proves their vision is having impact. Produces a roadmap home — an AGENTS.md (concepts + folder conventions, written once) over per-vision folders, each holding roadmap.md (vision + strategic intent + lagging outcome), bets/<bet>/bet.md, and metrics/<metric>/ (a probe + a live baseline). The front bookend of the Human Loop's Strategy phase; the upstream sibling of /intent.
---

# roadmap

Run a conversation that turns a vision into a coupled set of artifacts:

- `AGENTS.md` — **orientation**: static conventions explaining what the taxonomy means
  (vision, strategic intent, lagging/leading metric, bet, probe) and what each folder path
  means, so anyone browsing the tree understands it. Written once; the folder structure
  itself is the map — there is no maintained index.
- `<vision-name>/roadmap.md` — the **vision** (narrative direction) plus its **strategic
  intent(s)** — the chosen focus and the **lagging outcome** that proves the vision is
  working — and a loose backlog of problems.
- `<vision-name>/bets/<bet>/bet.md` — one **bet** (initiative): a *problem*, a falsifiable
  **hypothesis**, the **expected value**, and a (strongly suggested) **leading** metric.
- `<vision-name>/metrics/<metric>/measure-outcome.sh` + `readings.log` — the **probe**: how
  a metric is read, and a **baseline** taken by running it against the live world now.

A metric and its probe are **born together** here, the mirror of how `/intent` is born from
a PRD and its `run-prd-test.sh`. The discipline is the mirror of `/intent`'s "failing for
the right reason": there, running the runner against unbuilt code proves *done is
executable*; here, running the probe against the live world proves *impact is measurable*.

This is a **human-attentive** skill — the front bookend of the **Strategy** phase, between
Understanding (`/wiki-init`) and Intent (`/intent`). A person is present: explain as you
go, so they leave with a sharpened vision they own and can defend.

You are a **coordinator and a forcing function, not a strategy consultant.** You don't
supply the vision — you sharpen theirs by refusing to let an outcome stay fuzzy. The
domain truth lives with the human (and their Understanding wiki); the project's
verification conventions live with the **Expert**. You own the conversation and the
discipline.

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
- **PRD (option)** — a *solution* slice. `/intent`'s job, downstream. Verified by a runner.

## The philosophy (read this; embody it as you work)

- **R1 — Artifacts born together.** Prose visions drift; "impact" becomes an argument. A
  reading doesn't. The vision doc, the bet, and the probe + baseline are born from one
  conversation; none is finished without the others.
- **R2 — Outcomes, not features.** A roadmap is not a feature list with dates. A bet is a
  *problem* tied to a metric, not a solution. The moment you're naming a component ("the
  onboarding wizard"), stop — that's `/intent`'s altitude. Bet on the outcome it produces.
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
- **R6 — The bet is the unit of outcome; the PRD is the unit of output.** A bet decomposes
  into one *or many* PRDs (`/intent` slices it, lazily). The metric lives on the **bet**,
  never on a PRD — welding a lagging real-world number onto a deterministic pre-merge runner
  breaks the altitude line. Name the problem and the hypothesis here; don't pre-slice.
- **R7 — Smallest bet that would move the needle.** Decompose the vision into the *next*
  problem worth attacking, not the whole sequence — the Product Kata's next *target
  condition*. The backlog is loose and expected to churn; you learn from each shipped bet
  before committing the next.
- **R8 — Coordinator, not knowledge holder.** The instrument — which warehouse, which
  event, who to interview — comes from the human and the project. Mirror the Expert's
  verification patterns where one exists; otherwise ground in what the product emits.
- **R9 — The human owns the fork; you coach it.** Whether a new idea becomes a **new bet**
  under an existing vision or a **new vision** (a new `<vision-name>/` folder) is the
  human's call. Coach with the vocabulary: a new vision usually means a new *strategic
  intent* (a different big lagging focus); a new bet is a fresh initiative under the current
  one. Warn against **peanut-buttering** — don't fork per idea — then follow their lead.
  Never auto-fork.
- **R10 — Transparent, shared understanding.** Explain → confirm → act → take feedback. The
  human ends able to read `AGENTS.md`, `roadmap.md`, a `bet.md`, and the probe, and to
  defend why each line is there. Ending with **no artifact** is valid — sometimes they just
  needed to think the vision out loud.

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
- `assets/AGENTS.md.template` — the orientation file: the taxonomy + folder-path
  conventions. Written once into a new home; never maintained as a map.

## The guided flow

### Step 0 — Preflight & locate the home
Decide where the **roadmap home** lives and confirm its working tree is clean.
- **Single-repo product** → a `roadmap/` folder at the repo root, sibling to `prds/`. The
  `AGENTS.md` lives **inside** `roadmap/`.
- **Multi-repo product** (a UI repo + an API repo + …) → the roadmap is **its own repo**;
  `AGENTS.md` lives at the **repo root**. Offer to `git init` / create the folder if absent.

Load the Expert (`.claude/skills/expert/references/*.md`) if a code repo nearby has one —
it grounds *how this project reads things*. No Expert is fine and expected for a roadmap
home.

### Step 1 — The fork question (human-owned, coached) — R9
Early, ask: **is this a new vision, or a new bet under an existing one?** If the home
already exists, list its `<vision-name>/` folders to show what's there (and read `AGENTS.md`
once for the conventions). Coach with the vocabulary — a new
vision means a new *strategic intent* (a different big lagging outcome); a new bet is an
initiative under an existing intent; don't fork per idea (peanut-buttering). The human
decides. A new vision = a new `<vision-name>/` folder; a new bet = a new `bets/<bet>/`
under an existing `<vision-name>/`.

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
loosely in `roadmap.md`'s backlog. Do **not** decompose the bet into features.

### Step 6 — Build the probe(s) + write the artifacts (R1, R4)
Draft `metrics/<metric>/measure-outcome.sh` (and its `query.sql` / `rubric.md`) from
`references/probe-recipes.md` for the bet's leading metric and the intent's lagging one.
Write `<vision-name>/roadmap.md` (vision + strategic intent + backlog — **not** an index;
see `references/roadmap-template.md`). **You draft the probe; the human reviews** (R8).

### Step 7 — Baseline loop (the right-reason proof, R4)
`chmod +x` each probe and **run it against the live world.** A clean current reading → write
it as line 0 of `readings.log` (`<ts> | <value> | baseline | -`). Can't read it → fix the
instrument, or pick a metric you can read (`references/baseline-right-reason.md`). Show the
human the number and what it proves.

### Step 8 — Ensure AGENTS.md, commit, return
If `AGENTS.md` is **absent**, create it from `assets/AGENTS.md.template`. If it **already
exists, leave it untouched** — it's static conventions explaining the folder taxonomy,
*not* a map you maintain. The folder structure itself is the map; there is no index to keep
in sync. Commit the home:
```
git add AGENTS.md <vision-name>/        # AGENTS.md only on first run; roadmap.md, bets/<bet>/, metrics/<metric>/
git commit -m "Roadmap: <vision> — bet <bet> (baseline <value>)"
```
Tell the human the next move: `/intent` the bet to slice it into PRDs, and
`/evaluate-outcome` once the bet ships end-to-end. Leave the tree clean.

## Invocation & output contract

- **Invoked by:** a human (`/roadmap`, optionally with a free-text seed). **Not** the
  dispatcher — a human-in-the-loop skill, like `/intent` and the evaluate skills.
- **Outputs (in the roadmap home):** `AGENTS.md` (static orientation, written once on the
  first run only), and under `<vision-name>/`: `roadmap.md`, `bets/<bet>/bet.md`,
  `metrics/<metric>/measure-outcome.sh` (executable) + what it reads + `readings.log` with a
  baseline line. Re-runnable per bet and per vision.
- **How the chain reacts:** nothing automatic. The home is **read** by `/intent` (path
  passed inline) to ground a PRD's *why*, and **read + appended** by `/evaluate-outcome`
  post-ship. The harness never builds from it — it lives outside `prds/`, carries no
  sentinels (Invariant 2 stays clean).

## Idempotency & re-running
- Re-running against an existing home: read `AGENTS.md`, show what's there, and **add a new
  bet** (under an existing vision) or **a new vision** (a new `<vision-name>/`) per the fork
  decision — never start over. One home, many visions and bets.
- A metric that already has a baseline is not re-baselined — that's `/evaluate-outcome`'s
  job (it appends readings; never rewrites line 0).
- If a previous run left an uncommitted roadmap in the tree, offer to resume it.

## Hard nevers
- **Never emit a feature roadmap.** Bets are problems tied to metrics, never features with
  dates (R2).
- **Never finish a metric without a baseline reading** (R4).
- **Never put a metric into a PRD runner.** The metric lives on the bet; `run-prd-test.sh`
  checks *built*, never *moved* (R6).
- **Never pre-slice a bet into PRDs** — that's `/intent`'s job (R6, R7).
- **Never auto-fork a vision.** The new-roadmap-vs-new-bet call is the human's (R9).
- **Never make `roadmap.md` an index, and never maintain a map.** `AGENTS.md` is static
  conventions written once; the folder structure is the map. Don't append to `AGENTS.md` on
  re-runs (Step 8).
- **Never hand the probe to the human to author** (R8); **never commit a probe you haven't
  run** (R4); **never write a secret into the home** — access is a pointer.
