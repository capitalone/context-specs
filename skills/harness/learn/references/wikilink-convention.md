# Wikilink convention

**Hackable seam.** The link syntax `/learn` uses inside `expert/references/`,
and the lint that enforces it. AGENTS.md is **out of scope** — it uses regular
markdown links and has its own validator (`check-agents-md.sh`).

## Why wikilinks

Reference files cross-link each other (a `how-to-*` file points at a
`[[concept-*]]` it depends on, an `invariant-*` points at the `[[pattern-*]]` it
hardens, etc.). Two options:

- Regular markdown links: `[text](concept-architecture.md)`. Verbose, ties text
  to filename, and rots when files are renamed.
- Wikilinks: `[[concept-architecture]]`. Short, basename-only, near-universal in
  Obsidian-style notes. **Agents already know how to traverse these** without
  prompting.

We pick wikilinks for the Expert's internal cross-references because the cost
of one extra link-resolution rule is bought back many times over in
readability and stable refactoring.

## The spec

A wikilink is the literal token `[[<slug>]]` where `<slug>` matches
`[a-z0-9-]+`.

Resolution: `[[<slug>]]` refers to the file `<slug>.md` in the **same directory**
as the file that contains the link (i.e. `.claude/skills/expert/references/`).

- No paths. No leading `./`. No subdirectories.
- No `.md` extension inside the brackets.
- No alias form (`[[slug|display text]]`) for now — keep the syntax minimal.
- The link target file must exist.

## Valid

```markdown
For setup, see [[how-to-run-the-project]].
The repo layer must obey [[invariant-no-repo-imports-service]].
This pattern complements [[concept-architecture]].
```

## Invalid

```markdown
See [[./how-to-run-the-project]].              ← no path
See [[how-to-run-the-project.md]].             ← no extension
See [[How-To-Run-The-Project]].                ← lowercase only
See [[how-to-run-the-project|setup guide]].    ← no alias form
See [[expert/how-to-run-the-project]].         ← no directory prefix
```

## Enforcement

`scripts/check-expert-links.sh` (next to `check-agents-md.sh`) walks every
`expert/references/*.md`, extracts every `[[...]]` token, and asserts each
resolves to an existing `.md` file in the same directory.

- **Broken link → exit 1.** The PR fails. Fix the link or restore the file.
- **Orphan files** (no inbound wikilink from any other reference) → warn only,
  do not fail. Top-level concepts can legitimately be orphans.
- **Cycles** (A → B → A) → informational only. Small cycles between mutually
  related concepts are fine.

Wire the script into `scripts/local-checks.sh` next to `check-agents-md.sh` so
the same gate that flags a stale AGENTS.md pointer also flags a stale Expert
wikilink.
