# Subagent Prompt Template

Use this template when spawning the `slice-implementer` subagent. Fill in the placeholder values for each slice.

## Template

```
You are implementing slice <number> (<name>) of the <mainspec-name> mainspec.

IMPORTANT: Your working directory is <working-directory-absolute-path>.
Before doing any work, run:
  cd <working-directory-absolute-path>

Read the slice file at:
  <absolute-spec-file-path>
  (This is an absolute path — it may be outside your working directory)

Follow the implement-slice workflow (preloaded in your context) to implement the slice:
Implement → Unit Tests → Reflect

Report your result:
  - SUCCESS: all code implemented, tests pass, Reflect outcome (no-op | add | edit | delete).
    List key files created/modified (including any Expert reference files touched during Reflect).
  - FAILURE: describe what went wrong and where you stopped.

Do NOT use AskUserQuestion — no human is in the loop.
Do NOT run any git commands (add, commit, push) — the orchestrator handles git.
Do NOT create a PR — the orchestrator handles all git operations.
Do NOT modify files outside your assigned slice scope (exception: `.claude/skills/expert/references/`
  edits during the Reflect step are explicitly in-scope).
Do NOT use git worktree commands — you are already in the correct directory.
```

## Placeholder Reference

| Placeholder | Source | Example |
|------------|--------|---------|
| `<number>` | Slice Dependency Map → slice number | `3.3` |
| `<name>` | Slice Dependency Map → slice name | `BarChart Component` |
| `<mainspec-name>` | mainspec.md → feature slug | `svg-and-charts` |
| `<working-directory-absolute-path>` | Repo root | `/home/user/repo` |
| `<absolute-spec-file-path>` | `specs/<feature>/slices/<number>-<kebab-name>.md` (resolved to absolute path) | `/home/user/repo/specs/svg-and-charts/slices/3.3-barchart-component.md` |

## Usage

Spawn one subagent at a time. Wait for completion before spawning the next.

```python
Agent(
    subagent_type="slice-implementer",
    mode="bypassPermissions",
    name="slice-3.1",
    description="Implement slice 3.1",
    prompt="<filled template for slice 3.1>"
)
# Wait for completion
# Orchestrator runs: git add, git commit, git push
# Then spawn next slice
```
