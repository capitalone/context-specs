---
name: roadmap-init
description: One-time, guided setup of a product roadmap home — the strategy vault the Human Loop's Strategy phase works in. Scaffolds the AGENTS.md conventions (taxonomy + folder map + backlog schema), the folder skeleton, installs the recurring /roadmap skill into the home, and points the home repo's root AGENTS.md at it. Use when a product-minded person wants to start, create, bootstrap, or initialize a roadmap / product-strategy home / roadmap vault — before there is any vision, bet, or backlog. The front of the Human Loop's Strategy phase; the one-time setup upstream of /roadmap and /intent.
---

# roadmap-init

Stand up a **product roadmap home**, step by step, as a guided session. The person should
finish understanding exactly what was created, why it matters, and how to use it — with every
artifact reviewed and tweakable.

This skill is **one-time setup**, the mirror of `/wiki-init`. It does **not** run the strategy
conversation and writes **no** vision, bet, or backlog item. It scaffolds the home's static
conventions, installs the recurring skill that *does* the thinking, and hands off. The
recurring work — sharpening a vision into a measurable bet — is **`/roadmap`**, run as often
as you like once the home exists.

> **The split (and why):** `roadmap-init` is to `/roadmap` what `/wiki-init` is to `/ingest`.
> Setup is rare and mechanical; the conversation is frequent and human-attentive. Separating
> them keeps each one's trigger and instructions sharp, and lets the home carry its own
> operating skill — the way a wiki vault carries its own `/ingest`/`/query`/`/lint`.

## What a roadmap home is

A **product strategy home**: an Obsidian-style vault that holds *why we build, how we'll know
it worked, and the work in flight* — above any one repo. It is **read** by `/intent` (to
ground a PRD's *why*) and `/evaluate-outcome` (to read a bet's trajectory), and **appended**
by `/intent` (register-back) and `/evaluate-pr` (follow-up filing). The build harness never
builds from it — it lives outside any `prds/` and carries no sentinels.

The home explains *itself*: the `AGENTS.md` conventions you scaffold here are what every
downstream skill defers to, so none of them carry the roadmap's schema. **Get these
conventions right and the rest of the chain stays thin.**

## The philosophy (embody it; don't recite it)

- **I1 — Setup, not strategy.** You create the *container*, never its contents. No vision, no
  bet, no metric, no probe, no baseline is written here — those are `/roadmap`'s job, born
  from a conversation this skill deliberately does not have. If the person starts pitching a
  vision, scaffold the home and point them at `/roadmap`.
- **I2 — The conventions are the product.** What you scaffold is *static conventions written
  once*: the taxonomy, the folder map, and the backlog schema. They are the single source of
  truth the whole chain reads. The folder structure is the map — there is **no** maintained
  index, and these files are not re-touched on a normal re-run.
- **I3 — The home carries its own skill.** Install the recurring `/roadmap` skill into the
  home repo's `.claude/skills/` and point that repo's root `AGENTS.md` at the home and the
  skill — so anyone who opens the repo (human or agent) can both *find* the strategy home and
  *operate* on it, without a separate install.
- **I4 — Everything reversible.** Plan the scaffold, show it, get approval, then write — and
  do it in a git repo so any change can be seen and reverted. Refuse to clobber an existing
  home; a populated target path means *re-run, diff, ask* (see "Idempotency").
- **I5 — Transparent, shared understanding.** Explain → confirm → act → take feedback. The
  person ends able to read the scaffolded `AGENTS.md`, knows the home is theirs, and knows the
  next move is `/roadmap`.

## How to run this skill

You are a guide, not a script runner. For **every** step that writes to disk or runs a git
operation: **explain what you're about to do and why → confirm → do it → show the result →
take feedback.** The conventions you scaffold come from `assets/`; tailor only the obvious
fillers (product name, repo list), never the disciplines inside.

Assets you scaffold (written once):
- `assets/AGENTS.md.template` — the home orientation: the taxonomy (vision → strategic intent
  → bet → backlog item → metric → PRD) + the folder-path conventions + the Obsidian-vault
  rules. *(Hackable seam: the taxonomy + folder map.)*
- `assets/backlog/AGENTS.md.template`, `assets/backlog/{feature,bugfix}/AGENTS.md.template` —
  the **backlog schema** (frontmatter, item types, status lifecycle, the altitude line). The
  schema lives **here**, so downstream skills (`/roadmap`, `/intent`, `/evaluate-pr`) carry
  none of it — they read these. *(Hackable seam: the item schema.)*
- `assets/root-AGENTS-pointer.md.template` — the snippet to add to the **home repo's root**
  `AGENTS.md`, calling out the roadmap folder and the `/roadmap` skill that operates on it.

## The guided flow

### Step 0 — Locate the home & confirm a clean tree
Decide *where* the roadmap home lives, and confirm its working tree is clean.
- **Single-repo product** → a `roadmap/` folder at the repo root, sibling to `prds/`. The home
  `AGENTS.md` lives **inside** `roadmap/`; the repo whose root `AGENTS.md` you point at (Step 4)
  is this same repo.
- **Multi-repo product** (a UI repo + an API repo + …) → the roadmap is **its own repo**; the
  home `AGENTS.md` lives at the **repo root**. Offer to `git init` / create the folder if absent.

The home sits *above* any one repo. Refuse to clobber an existing home at the chosen path —
treat that as a re-run (see "Idempotency").

### Step 1 — Plan-pass
Emit the concrete scaffold plan: the directory skeleton, the four `AGENTS.md` files, where the
`/roadmap` skill will be installed, and the root-`AGENTS.md` pointer. **Stop and wait for
approval**, unless `--yolo` was passed. Apply edits, re-emit, loop until approved.

### Step 2 — Scaffold the conventions + skeleton
Write the static conventions (once) and the empty folder skeleton:
```
<home>/
  AGENTS.md                       ← assets/AGENTS.md.template
  backlog/AGENTS.md               ← assets/backlog/AGENTS.md.template
  backlog/feature/AGENTS.md       ← assets/backlog/feature/AGENTS.md.template
  backlog/bugfix/AGENTS.md        ← assets/backlog/bugfix/AGENTS.md.template
```
Add a `.gitkeep` to each otherwise-empty content dir so the structure is committed and visible
on clone (git doesn't track empty dirs). Do **not** create any `<vision-name>/` folder — visions,
bets, metrics, and backlog items are `/roadmap`'s output, born from a conversation, not here (I1).

### Step 3 — Install the recurring `/roadmap` skill into the home repo
Vendor the recurring skill into the home repo so the home carries its own operating skill (I3).
Locate the installed `roadmap` skill — the sibling of this skill in the same skills directory
(`../roadmap/`), or `~/.claude/skills/roadmap/` — and copy its `SKILL.md` + `references/` into:
```
<home-repo>/.claude/skills/roadmap/
```
For a **single-repo** product the home repo is the app repo (so this is its `.claude/skills/`);
for a **multi-repo** product it's the standalone roadmap repo. If the skill is already present
and current there, leave it; if it's an older copy, offer to update it (see "Idempotency").

### Step 4 — Point the repo's root AGENTS.md at the home
Add the `assets/root-AGENTS-pointer.md.template` snippet (tailored with the home's path) to the
home repo's **root** `AGENTS.md` — creating that file if absent — so anyone opening the repo
learns the roadmap home exists and that `/roadmap` operates on it. Don't duplicate the snippet
on a re-run; update it in place if the path changed.

### Step 5 — Commit & hand off
For a standalone home, `git init` first if needed. Commit the scaffold (confirm first):
```
git add AGENTS.md backlog/ .claude/skills/roadmap/   # + the repo-root AGENTS.md pointer
git commit -m "roadmap-init: scaffold strategy home + install /roadmap"
```
Leave the tree clean. Tell the person the next move plainly: **run `/roadmap`** to sharpen a
vision into a measurable bet — that conversation is where the first `<vision-name>/` folder,
bet, metric, and baseline get written. Name the payoff: a home with sharp conventions keeps
`/intent` and `/evaluate-pr` thin, because they all read these `AGENTS.md` files.

## Invocation & output contract

- **Invoked by:** a human (`/roadmap-init`, optionally `--yolo`). **Not** the dispatcher — a
  one-time human-attentive setup skill, like `/wiki-init` and `/harness-init`.
- **Outputs:** in the home — the `AGENTS.md` conventions (home + nested `backlog/`), the empty
  folder skeleton, and a vendored copy of the `/roadmap` skill under `<home-repo>/.claude/skills/`;
  in the home repo — a root `AGENTS.md` pointer; and (for a standalone home) an initialized git
  repo. **No** vision, bet, metric, probe, baseline, or backlog item — those are `/roadmap`'s.
- **Completion:** the committed home. There is no sentinel — the home's existence is the signal
  that the Strategy phase has a place to work.

## Idempotency & re-running
- Safe to re-run. If the target path already holds a home, **diff against it** rather than
  clobbering: offer to update the canonical files (the four `AGENTS.md` conventions, the
  vendored `/roadmap` skill, the root pointer) to the latest templates, and **leave all
  `<vision-name>/` content — visions, bets, metrics, backlog items — untouched** unless asked.
- The conventions are *static, written once* (I2). On a normal re-run you are only refreshing
  canonical scaffolding to the latest version, never rewriting strategy content.

## Hard nevers
- **Never write strategy content here.** No vision, bet, metric, probe, baseline, or backlog
  item — that's `/roadmap` (I1). This skill only builds the container.
- **Never clobber an existing home.** A populated target path means re-run, diff, ask (I4).
- **Never make an index or maintain a map.** The `AGENTS.md` files are static conventions; the
  folder structure is the map. Don't add a vision list to any scaffolded file.
- **Never inline the backlog schema anywhere but `backlog/AGENTS.md`.** It has one home; every
  downstream skill reads it from there.
- **Never write a secret into the home** — metric access (added later by `/roadmap`) is a
  pointer, never a credential.
