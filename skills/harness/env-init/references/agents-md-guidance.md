# Generating AGENTS.md

`AGENTS.md` is the agent contract — eagerly loaded into every agent's context at
the start of every session, in every worktree. It is **vendor-neutral** (the open,
portable memory-file standard), which is what makes the harness portable: any
harness (Claude Code, a server runner, a future tool) reads it and learns the
project's onboarding, the Expert, the skill chain, the branch lifecycle, and the
non-bypassable verification layers. Using the neutral file (rather than a
tool-specific one) also keeps the project's memory portable and its own — no
lock-in to a single tool.

env-init generates it from `assets/AGENTS.md.template` plus a codebase scan
(project-discovery.md). Most of the template is canonical and stays verbatim; only
the bracketed parts are filled from the scan.

## Keep it tight — it's a map, not an encyclopedia

Everything in `AGENTS.md` is paid for in tokens on *every* invocation, because it's
eager. The Expert is the opposite — pulled on demand — so dense knowledge belongs
there, with AGENTS.md pointing to it. Cap the root file at ~150 lines (the freshness
lint `check-agents-md.sh` enforces this). Setup mechanics, multi-developer
coordination, and hackable seams don't belong in `AGENTS.md` at all. If you're
tempted to explain *how to set up* the harness in `AGENTS.md`, stop —
`AGENTS.md` tells an agent how to *operate* in this repo, not how it was built.

## What to fill from the scan

| Bracket in template | Fill from |
|---------------------|-----------|
| `[Project Name]` | repo name / `package.json` `name` / README title |
| project config refs in the verification section | the linters/formatters/typecheckers discovered (project-discovery.md) — e.g. "Pre-commit hooks: eslint + prettier via husky" |
| any project-specific onboarding pointer | only if the project has a genuinely load-bearing doc an agent must read first |

## What stays verbatim (do not editorialize)

- The **Onboarding** list (Expert, PRDs, specs).
- The **Expert** section — its role as long-term memory, the "consult before
  non-trivial work" rule, "reflects what's committed to main."
- The **skill chain** table — the state machine. Canonical; do not reorder or
  reword the trigger conditions.
- The **Memory: two shapes, one write path** section.
- The **branch lifecycle** block.
- The **non-bypassable verification** section's four layers.

## The Expert caveat for fresh projects

The Expert (`.claude/skills/expert/`) does not exist on a brand-new project — it is
born from the first merge to main (the bootstrap case of `/learn`). `AGENTS.md`
still references it, because by the time the harness completes its first cycle the
Expert will exist. Don't strip the Expert section just because the directory isn't
there yet — but DO tell the user, during setup, that the Expert will be empty until
their first feature merges, and that's expected.

## Nested AGENTS.md files

The root file is usually all a project needs at setup. Nested AGENTS.md files (in
subfolders) are added *later, by `/learn`*, only when a merge introduces a
folder-local rule that clears the high bar — they're not part of initial setup.
Mention this so the user knows the memory will grow itself over time.

## Present it as a diff

Show the user the filled `AGENTS.md` and point out exactly which lines you changed
from the template and why (the scan finding behind each). Let them edit before you
commit. This is their contract; they should own every line.
