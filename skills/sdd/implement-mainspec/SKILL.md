---
name: implement-mainspec
description: Implements a mainspec end-to-end by delegating each slice to a `slice-implementer` subagent in dependency order, committing to `feature/<feature>` directly. Agent-first — invoked headless by the harness dispatcher with the feature slug. No human-in-the-loop, no approval gates.
---

# Implement Mainspec

Implements all slices from a mainspec in dependency order, sequentially. Agent-first: invoked headless by the harness dispatcher, runs end-to-end with no approval gates, exits.

## Invocation Contract

**Invoked by the dispatcher as:** `claude -p "/implement-mainspec <feature>"`, run from inside the feature worktree (the dispatcher `cd`s into it).

**Single argument:** `<feature>` — kebab-case feature slug. The mainspec path is `specs/<feature>/mainspec.md` relative to cwd.

**Inputs read from disk (paths relative to cwd):**
- `specs/<feature>/mainspec.md`
- `specs/<feature>/slices/*.md`
- Current `feature/<feature>` branch state.

**Outputs to disk / remote:**
- All implementation code committed and pushed on `feature/<feature>`, one commit per slice.

**No sentinel.** The dispatcher's success signal for this step is `./prds/<feature>/run-prd-test.sh` exits 0, verified externally. The final slice's Success Criteria encodes this into a slice so completing all slices implies the PRD test passes. We do not write a sentinel file — the *dispatcher* records the green result in `specs/<feature>/.prd-passed` once the runner first exits 0; this skill neither writes nor reads that file.

**Idempotency:**
- On every invocation, inspect `feature/<feature>` git history. Determine which slices are already committed (look for commits like `Implement slice <n>: <name>`).
- The orchestrator reads the mainspec's Slice Dependency Map inline to plan its execution order.
- Work only on remaining slices.
- If all slices appear committed, exit cleanly. The dispatcher will re-verify the PRD test externally.

**No approval gates anywhere.** No `AskUserQuestion` for plan approval, default-branch warning, or any other decision. Every decision is deterministic or deferred to the next dispatcher tick.

## Workflow Overview

```
Phase 1: Parse & Resume — Read mainspec Slice Dependency Map, determine execution order, inspect feature/<feature> for already-committed slices
Phase 2: Implement — Delegate each remaining slice to slice-implementer subagent (foreground). Orchestrator handles git directly on feature/<feature>.
Phase 3: Log — Log final status of this invocation to stdout for observability
```

## Pre-conditions

The dispatcher guarantees a clean worktree on `feature/<feature>` before invoking. Verify deterministically and exit on violation — the dispatcher will re-derive state on the next tick.

1. **Git repository** — `git rev-parse --git-dir` succeeds. If not, exit non-zero.
2. **Current branch matches `feature/<feature>`** — must match the argument exactly. If not, exit. (Never create the feature branch; the dispatcher's atomic rename from `prd/<author>/<feature>` did that.)
3. **Clean working tree** — `git status --porcelain` empty. If not, exit (the dispatcher's wipe should guarantee this; if it trips, something upstream is wrong).
4. **Remote configured** — `git remote get-url origin` succeeds. If not, exit.

## Phase 1: Parse & Resume

### Slice Ordering

Read the mainspec's "Slice Dependency Map" table directly. For each slice, note its number, name, and `Depends On` list. Use that understanding to plan the execution order — slices whose dependencies are already committed (or have no dependencies) can run next; slices with outstanding dependencies wait.

Reference the slice file path convention: `specs/<feature>/slices/<number>-<kebab-name>.md`.

### Resume Detection (Idempotency)

Before implementing anything, inspect what's already committed on `feature/<feature>`:

```
1. git fetch origin
2. For each slice in the mainspec:
   - Check whether a commit referencing "Implement slice <number>:" exists in
     git log feature/<feature> (e.g., git log --oneline --grep "Implement slice <number>:").
   - If yes, mark slice as ALREADY-COMMITTED. Skip it.
   - Otherwise, mark slice as REMAINING.
3. If all slices are ALREADY-COMMITTED, log "all slices committed, nothing to do" and exit cleanly.
4. Otherwise, proceed with REMAINING slices in their dependency order.
```

### Plan Logging (No Approval)

Log the computed plan to stdout for observability — which slices are remaining vs. already-committed. **No approval gate, no `AskUserQuestion`.** Proceed directly to Phase 2.

```
## Execution Plan: <mainspec-name>
Total slices: N (already-committed: M, remaining: K)
Remaining order:
1. Slice X.Y: <name>
2. Slice X.Y: <name>
```

## Phase 2: Implementation

The preconditions already guaranteed we are on `feature/<feature>`, so we commit directly to it. No default-branch warning, no approval prompt.

For each **REMAINING** slice in dependency order (skipping already-committed ones from Phase 1):

1. Create TODO list — One item per slice.
2. Mark slice in_progress.
3. Delegate to a `slice-implementer` subagent (foreground, NOT background):
   - Use `subagent_type: "slice-implementer"` and `mode: "bypassPermissions"`.
   - Use the prompt template from `references/subagent-prompt-template.md`.
   - Set working directory to the repo root.
   - Wait for subagent to complete.
4. After subagent completes successfully:
   - Orchestrator runs `git status` to detect changes.
   - Orchestrator runs `git add <changed-files>` (only files the subagent created/modified).
   - Orchestrator runs `git commit -m "Implement slice <number>: <name>"`.
   - Orchestrator runs `git push origin feature/<feature>`.
5. If subagent reports FAILURE:
   - Log the failure (slice number, error text) to stdout.
   - Do not commit any partial state.
   - Exit. The dispatcher will re-fire on the next tick; idempotency in Phase 1 will skip the already-completed slices and retry this one.
6. Mark slice complete.

After all remaining slices: proceed to Phase 3 (Log).

## Phase 3: Stdout Log (Observability Only)

There is no human to report to. Write a concise stdout log of what this invocation did so the dispatcher's log is readable.

```
## /implement-mainspec invocation summary: <feature>
Skipped (already-committed): <list of slice numbers> (or none)
Implemented this invocation: <list of slice numbers>
Failed this invocation: <list of slice numbers> (or none)
Branch: feature/<feature> (pushed)
```

## TODO Structure

```
[ ] X.Y-<slice-name>
[ ] X.Y-<slice-name>
...
```

## References

- **Subagent prompt template**: Read `references/subagent-prompt-template.md` when spawning subagents in Phase 2
- **Error handling**: Read `references/error-handling.md` when any phase encounters errors

## Guidelines

**DO:**
- Log the execution plan to stdout for observability (no approval gate; proceed directly).
- Use absolute paths for all spec file references.
- Delegate slice implementation to `slice-implementer` subagents — orchestrator stays lean.
- Use `subagent_type: "slice-implementer"` and `mode: "bypassPermissions"` for all subagent spawns.
- Handle all git operations (add, commit, push) in the orchestrator — subagents do NOT run git. This includes any Expert-file changes a subagent's Reflect step wrote.
- Use `git status` to detect changed files after subagent completion.
- Read only the current slice file — never read all slices at once.
- Treat the current branch as the feature branch (must match `feature/<feature>`); never create it.
- Inspect `feature/<feature>` git history at the start of every invocation to determine which slices are already committed; idempotency depends on this.
- On any failure: log clearly, exit. The dispatcher's next tick is the retry mechanism.

**DON'T:**
- Use `AskUserQuestion` anywhere. The dispatcher provides no input, and the human is not in the loop.
- Implement slices inline — always delegate to `slice-implementer` subagent.
- Read files to embed in subagent prompts — subagents read their own files.
- Skip slices or implement out of order (within remaining work).
- Proceed with failing tests.
- Over-engineer beyond slice scope.
- Create worktrees, per-slice branches, or PRs for individual slices.
- Create a sentinel file for this skill. The dispatcher's success check is `./prds/<feature>/run-prd-test.sh` exit code, not a sentinel.
