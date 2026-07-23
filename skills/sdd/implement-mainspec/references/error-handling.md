# Error Handling & Recovery

Reference for handling errors during mainspec implementation. Read this when any phase encounters errors.

Agent-first model: there is no human in the loop and no orchestrator session waiting on stdout. The retry mechanism is the harness dispatcher: each tick wipes uncommitted state and re-invokes `/implement-mainspec`. Idempotency (Phase 1 resume detection) is what makes retries safe — the skill identifies which slices are already committed and works only on remaining ones.

## 1. Subagent Fails Implementation

- Log error details from subagent output to stdout for observability.
- Mark the slice as failed for this invocation; do not commit any partial state.
- Exit. The dispatcher's next tick will re-fire `/implement-mainspec`; Phase 1's idempotency check will skip committed slices and retry this one.


## 2. Push Fails

- Preconditions require a remote, so this means transient network / auth failure or remote rejection.
- Log and exit. The dispatcher's next tick will retry. There is no fallback to "local-only mode" — the harness model assumes remote is available.

## 3. Resuming After Interruption

- Every dispatcher tick wipes uncommitted state in the worktree (`git reset --hard HEAD && git clean -fd`) and re-invokes `/implement-mainspec`.
- The skill re-derives all state from disk on every invocation:
  - What's committed on `feature/<feature>` (Phase 1 idempotency check via `git log --oneline --grep "Implement slice"`).
- No checkpoint files or in-memory state to persist; the git history IS the state.
- **Feature branch:** must exist (dispatcher's atomic rename created it). The precondition check verifies HEAD matches `feature/<feature>`; exit if not.
