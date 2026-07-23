---
name: implement-slice
description: Implements a single slice with unit tests and a Reflect step. Agent-first — invoked by the slice-implementer subagent (under implement-mainspec). No human-in-the-loop.
---

# Implement Slice

Executes a single slice with unit tests and a post-implementation Reflect step. Agent-first: invoked by the `slice-implementer` subagent under the parent orchestrator (`implement-mainspec`). No human prompts.

## Invocation Contract

This skill is invoked by the `slice-implementer` subagent, not directly by the harness dispatcher. The subagent's prompt provides:

**Inputs:**
- `slice_path` — absolute path to the slice file (may be outside the working directory).
- `working_directory` — absolute path to the feature branch checkout (repo root).

**Outputs (uncommitted, in the working directory):**
- Implemented code matching the slice's specification.
- Unit tests created/updated.
- Optional: edits under `.claude/skills/expert/references/` if Reflect produced a high-bar update.

The parent orchestrator (`implement-mainspec`) handles git (add, commit, push) after this skill exits. Do NOT commit, do NOT run git operations, do NOT create PRs.

**Result reporting (to the calling subagent):**
- **SUCCESS**: list key files changed, tests passing, Reflect outcome (no-op | add | edit | delete).
- **FAILURE**: describe what went wrong. Reasons include: `test_failure` (unit tests red), `implementation_blocked` (spec contradicts the codebase).

## Workflow

1. **Read slice** - Load the entire slice file into context.
2. **Create TODO list** - Three items:
   - `{slice-name} - Implement`
   - `{slice-name} - Unit Tests`
   - `{slice-name} - Reflect`
3. **Implement** - Mark in_progress, implement all code specified in the slice.
4. **Unit tests** - Create/update unit tests for the implemented functionality. All tests must pass before proceeding.
5. **Reflect** - See the Reflection Protocol below.
6. **Complete** - Mark all TODOs complete, stop.

The working directory is the feature branch checkout. There should be no prior partial state to resume from — work as if the slate is clean.

## Reflection Protocol

Run only after Implement + Unit Tests are green.

### Step A — Load long-term memory

Invoke `/expert` so the skill body and its reference files are pulled into your context:

```
skill: "expert"
```
If absent, Reflect is a no-op. Never fail the slice on missing `/expert`.

Otherwise, read the reference files that overlap with what this slice touched (architecture area, patterns used, file types modified).

### Step B — Judge: add, edit, delete, or no-op

You now hold two things:
1. **Your experience implementing this slice** — what was confusing, what pattern you implemented, where the spec contradicted the actual codebase (already in your context window).
2. **The current long-term memory** — what `/expert` says about those areas (loaded in Step A).

High bar — default to **no-op** unless you have a strong reason to add, edit, or delete. Use the following table to guide your decision:

| Outcome | When to use |
|---------|------------|
| **NO-OP** (default) | Routine work, small adjustments, no contradiction. Prefer this. |
| **ADD** | A new fact, few-shot example, or procedure the project lacks. Use reference-file prefixes: `how-to-*` / `concept-*` / `pattern-*` / `invariant-*` / `example-*`. |
| **EDIT** | An existing reference is partially wrong; correct it in place. |
| **DELETE** | An existing reference contradicts merged code reality. |

Strong signals to act: slice got stuck for many iterations, or the slice spec explicitly contradicted code that already exists. Small deviations are noise — prefer NO-OP.

### Step C — Apply directly (only for add/edit/delete)

- Write the change to `.claude/skills/expert/references/`.
- If you added or deleted a reference file, update `.claude/skills/expert/SKILL.md`'s one-line index.
- Do NOT touch `AGENTS.md` — that is owned by `/learn` post-merge.
- The orchestrator commits these Expert-file changes with the slice and has full authority to resolve any resulting merge conflicts.

## TODO Structure

```
[ ] 1.3-user-auth - Implement
[ ] 1.3-user-auth - Unit Tests
[ ] 1.3-user-auth - Reflect
```

## Guidelines

**DON'T:**
- Use `AskUserQuestion`. No human is in the loop.
- Implement beyond the slice scope.
- Proceed with failing unit tests.
- Implement dependent slices (that's for implement-mainspec).
- Run git commands or create PRs — the parent orchestrator handles git.
- Fail the slice because `/expert` is unavailable or Reflect produced no update.
