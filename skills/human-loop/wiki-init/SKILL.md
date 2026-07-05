---
name: wiki-init
description: One-time, guided setup of a standalone LLM-maintained wiki — a Karpathy "LLM Wiki" style knowledge base for a problem domain and your general architecture best practices. Scaffolds an external wiki vault (its own git repo) with /ingest, /query, /lint commands and a conventions doc. Use when a developer wants to start, create, bootstrap, or initialize a wiki / second-brain / knowledge base to understand a problem space before building. The front of the Human Loop's Understanding phase.
---

# wiki-init

Stand up a **standalone LLM-maintained wiki**, step by step, as a guided expert
session. The developer should finish understanding exactly what was created, why
it matters, and how to use it — with every artifact reviewed and tweakable.

This wiki is **not** a project artifact. It is a durable knowledge base about a
**domain** and your **general architecture best practices** — knowledge that spans
projects. It lives **outside** any app codebase, in its own git repo. Its audience
is **you, the human**: the point is to build *your* mental model of the problem
space so that when you reach `/intent`, you can express sharper intent.

## The pattern (and the credit)

The shape here is **Andrej Karpathy's "LLM Wiki"** idea: rather than RAG
(retrieve-augment-generate at *query* time), you do the synthesis **once, at ingest
time**, into a persistent, cross-linked set of markdown pages that compound as
sources accumulate. The bookkeeping that makes humans abandon wikis — updating
cross-references, reconciling pages, keeping the map current — is exactly what an LLM
is good at. The human curates sources and asks questions; the LLM does the
maintenance. Credit the idea to Karpathy's LLM Wiki by name when you explain it.

What `wiki-init` ships is the **hardened** version of that idea — the disciplines that
keep it from rotting past ~100 sources. See `references/llm-wiki-pattern.md` for the
provenance and what we kept vs. changed, and `references/hardening-lessons.md` for the
disciplines and why each one earns its place.

## The philosophy (read this; teach it as you work)

Don't recite these — *embody* them, and surface the relevant one in plain language
when it explains a move you're making.

- **P1 — Synthesis at ingest, not at query.** The whole value is that connections are
  drawn *once* when a source lands, into durable pages — not re-derived on every
  question. `/query` reads the synthesized `wiki/`, never the `raw/` sources. If a
  question can't be answered from `wiki/`, the answer is "ingest more," not "let me go
  read the raw docs."
- **P2 — The wiki is for the human.** Pages are written to be *read by you* (and
  browsed in Obsidian), to build your model of the domain and its architecture. This is
  deliberately the opposite of an "AI-first vault." It is also the bright line against
  the project **Expert**, which is agent-first *code* memory: wiki = cross-project
  domain + architecture knowledge; Expert = per-project code memory.
- **P3 — Cite or stay silent.** Every non-trivial claim on a wiki page traces to at
  least one `[[source]]`. If you can't cite it, you don't write it — you say so and
  name a source to ingest. This is what makes the wiki trustworthy rather than a pile
  of confident guesses.
- **P4 — Plan before you write; everything reversible.** `/ingest` proposes a concrete
  change plan and waits for approval (unless `--yolo`). Combined with the wiki being its
  own git repo, nothing is ever an irreversible mutation — you can always see what
  changed and revert. Automation is "everything *reversibly*," not "everything always."
- **P5 — Three layers, one rule each.** `raw/` is immutable source material (never
  edited, except `/ingest` saving a URL fetch). `wiki/` is LLM-synthesized, cross-linked
  pages. `_meta/` is the ingest log + lint reports. The layering is what lets `/query`
  trust `wiki/` and lets you trace any claim back to its raw origin.
- **P6 — The wiki compounds; the lint keeps it honest.** Pages get *rewritten* as new
  evidence arrives (a superseded claim is updated, the old version preserved as a dated
  note — not silently appended-around). `/lint` is the periodic garbage-collector:
  broken links, orphans, stale claims, contradictions — surfaced for review, only the
  safe categories auto-fixed.
- **P7 — Understanding feeds Intent.** This is *why* you're building it. A richer wiki
  means a sharper `/intent`: you arrive at the PRD conversation already understanding
  the domain's concepts, the regulatory/architectural constraints, the trade-offs. Name
  this payoff to the user — it's the reason the phase exists.
- **P8 — Transparent, shared understanding.** Explain → confirm → act → take feedback.
  The user ends able to drive the wiki themselves and knows why each piece is there.

## How to run this skill

You are a guide, not a script runner. For **every** step that writes to disk or runs a
git operation: **explain what you're about to do and why → confirm with the user → do
it → show the result → take feedback and adjust.** Narrate from the references in plain
language; never guess.

Read first, before talking to the user:
- `references/llm-wiki-pattern.md` — so you can explain what an LLM Wiki *is* and credit
  Karpathy's LLM Wiki by name. *(Hackable seam: provenance + the kept-vs-changed list.)*
- `references/hardening-lessons.md` — the disciplines nothing you scaffold may drop, and
  why. *(Hackable seam: the discipline set lives here.)*

Then load `references/domain-discovery.md` when you reach Step 1.

Two kinds of artifact:
- **Canonical** (drop in from `assets/`, lightly tailored): the three commands
  (`ingest`/`query`/`lint`), the gitignore snippet, the README. Show them, explain them,
  invite tweaks — the disciplines inside are the same everywhere.
- **Tailored** (filled from the Step-1 conversation): the conventions doc
  (`WIKI-CONVENTIONS.md` → the wiki's `CLAUDE.md`) and the seeded `MOC.md` — domain name,
  page taxonomy, tag set, and `raw/` subfolders come from the human, not a codebase scan.

## Preconditions

`wiki-init` runs from wherever the human invokes it, but it **never writes into the app
codebase**. It creates a sibling/standalone directory and gives it its own git repo. If
the chosen path already contains a wiki, treat this as a re-run (see "Re-running") rather
than clobbering.

---

## The guided flow

### Step 0 — Locate the wiki (external, asked every run)

Decide *where* the wiki lives. **Ask the human for the path every run**, suggesting a
sibling of the current directory as the default — e.g. from `~/projects/survey-ready/app`
suggest `~/projects/survey-ready/<name>-wiki`. It must be **outside any app codebase**.
Confirm the name (`<name>` is usually the domain, e.g. `survey-ready`). Refuse to clobber
an existing wiki at that path. If the user keeps their notes somewhere specific, write
the wiki there instead of the sibling default — just keep it outside the app codebase.

The wiki gets **its own git repo** (Step 4), separate from any app repo.

### Step 1 — Domain discovery (conversation, no codebase scan)

Read `references/domain-discovery.md`. **Do not scan a codebase** — this wiki is about
the domain and the human's general architecture best practices, not any one project.
Interview the human:

- What problem space / domain is this? (e.g. "SNF survey readiness", "event-driven
  backend architecture".)
- What kinds of pages will dominate — domain **concepts**, named **entities** (orgs,
  roles, tools, regulations), **workflows** (procedures with steps)? Propose the
  taxonomy (concept / entity / workflow / source / index) adapted to their answer.
- What `raw/` subfolders fit their sources (articles, transcripts, tweets, gists,
  course material, repo notes)?
- A starting tag set (e.g. `[domain-slug, ...]`).

Propose all of the above back to them and refine until it fits.

### Step 2 — Plan-pass

Emit the concrete scaffold plan: the directory tree, the tailored conventions doc, the
three commands, the seeded `MOC.md`, the `README.md`, and where the wiki will live.
**Stop and wait for approval**, unless `--yolo` was passed. Apply edits, re-emit, loop
until approved.

### Step 3 — Write the scaffold

Create, at the chosen location:
- `raw/` with the agreed subfolders (immutable source material).
- `wiki/{concepts,entities,workflows,sources,indexes,inbox}/`.
- `_meta/ingest-log.md` and `_meta/lint-reports/`.
- The wiki's **conventions doc** — render `assets/WIKI-CONVENTIONS.md.template` tailored
  to the domain (name, taxonomy, tags, raw subfolders) and write it as the wiki's own
  `CLAUDE.md` (the doc the three commands all say "read first").
- The three commands into the wiki's `.claude/commands/`: `ingest.md`, `query.md`,
  `lint.md` (from `assets/commands/`).
- A seeded `wiki/MOC.md` from `assets/MOC.md.template` (the curated map; empty sections
  the first `/ingest` will fill).
- `README.md` from `assets/README.md.template` and the gitignore snippet as `.gitignore`.
- A `.gitkeep` in each otherwise-empty content dir (`raw/<sub>/`, `wiki/<type>/`,
  `_meta/lint-reports/`) so the structure is committed and visible on clone — git doesn't
  track empty directories. The first `/ingest` replaces them with real pages.

### Step 4 — Init the wiki's own repo

`git init` the wiki vault and make the first commit. This is the **wiki's own** repo,
separate from any app repo — it's what makes every later `/ingest` reversible. Confirm
with the user before committing.

### Step 5 — Report + handoff

Print the created layout, then walk the user through the loop they'll live in:
1. Drop a source into the right `raw/` subfolder (or pass a URL to `/ingest`).
2. `/ingest <path-or-url>` → it plans, then writes cited, cross-linked pages and updates
   the MOC + ingest log. (`--yolo` skips the plan approval.)
3. `/query "<question>"` → cited answers from `wiki/`; offers to promote novel synthesis.
4. `/lint` periodically → graph health.

Close by naming the payoff (P7): as the wiki grows, run `/intent` *after* spending time
here — you'll arrive understanding the domain and its architecture, and the PRD will be
sharper for it. If the project's `/intent` supports a wiki pointer, tell the user the
path to point it at; otherwise this wiki is theirs to read and query directly.

---

## Invocation & output contract

- **Invoked by:** a human (`/wiki-init`, optionally `--yolo`). Not the dispatcher — this
  is a human-attentive setup skill, like `/intent` and `/env-init`.
- **Outputs:** a standalone wiki vault at the chosen external path — `raw/`, `wiki/`,
  `_meta/`, the tailored conventions doc (`CLAUDE.md`), the three commands under
  `.claude/commands/`, a seeded `MOC.md`, a `README.md`, and an initialized git repo.
- **Completion:** the committed wiki vault. There is no sentinel — the wiki's existence
  is the signal that the Understanding phase has a home.

## Idempotency & re-running

- Safe to re-run. If the target path already holds a wiki, **diff against it** rather
  than clobbering: offer to update canonical files (the three commands, README) to the
  latest templates, and leave the tailored conventions doc + all `wiki/`/`raw/` content
  alone unless the user asks.
- Never delete or rewrite existing `raw/` or `wiki/` content on a re-run.

## Hard nevers

- **Never write into the app codebase.** The wiki is always external, its own repo.
- **Never derive the wiki from a codebase scan.** Domain and taxonomy come from the
  human (P2) — this is domain + architecture knowledge, not project memory.
- **Never embed the Karpathy gist URL** in the generated wiki or this skill. Credit
  "Karpathy's LLM Wiki" by name only.
- **Never let a generated command read `raw/` at query time** (P1) or write an uncited
  claim (P3) — the disciplines in `references/hardening-lessons.md` are load-bearing.
- **Never clobber an existing wiki.** A populated target path means re-run, diff, ask.
