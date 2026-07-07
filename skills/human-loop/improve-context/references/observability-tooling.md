# Observability tooling: the graduation seam

This skill is **local-first by design**: the build trail is local JSONL you read
directly, and nothing here requires a cloud service or an API key. This file is the
*graduation path* — what to reach for, and when, if you outgrow reading raw traces by hand.
It mirrors the rest of the harness's "stop at any rung" philosophy: the skills, the
artifacts, and the PR-comment contract don't change as you move up; only the *viewing and
aggregation* layer does.

> Rule of thumb: **don't adopt a tool until the manual path hurts.** For a single developer
> reading a handful of trails, `resolve-sessions.sh` + `jq` + the four lenses is faster than
> any dashboard. Graduate when *volume*, a *team*, or *continuous* evaluation makes the
> manual path the bottleneck — not before.

## When each rung earns its place

| Signal that you've outgrown local-first | Reach for |
|---|---|
| Trails are fine to read but raw JSON is tedious; you want a readable conversation view, tool-call folding, token counts | **A local viewer** (no cloud) |
| A *team* needs to review trails together, annotate them, and build shared datasets | **A hosted observability platform** |
| You want evals to run **online** — automatically, on every session, not just when a human invokes this skill | **A hosted platform with online evals** |
| Data residency / self-hosting is a hard requirement | **A self-hostable platform** |

## The rungs

### 1. Local viewer — `claude-code-trace` (no cloud)
Renders the same `~/.claude/projects/*/<id>.jsonl` files this skill already reads, as a
readable conversation with expandable tool calls, token counts, timestamps, and live
tailing. Fully local — nothing leaves the machine. Use it as a nicer lens over a trace the
resolver located; it changes *how you read*, not *what's true*. (`cctrace`, `cctrace --web`,
`cctrace --tui`.)

### 2. LangSmith — the managed rung (traces *are* Claude Code sessions)
The most natural hosted upgrade, because the build trail is literally Claude Code sessions
and LangSmith ships a **Claude Code plugin** that ingests them via env vars — no
instrumentation, no rewrite:

- Install the plugin; configure with env (`.claude/settings.local.json` or shell):
  `TRACE_TO_LANGSMITH=true`, `CC_LANGSMITH_API_KEY`, `CC_LANGSMITH_PROJECT`.
- **The harness hook point:** set `CC_LANGSMITH_METADATA` when launching `claude -p` to tag
  each session with the **feature and PR URL** (and author). That makes a PR's whole trail
  one queryable group in LangSmith's Threads view — the hosted analog of what
  `resolve-sessions.sh` does from the PR comment. (The dispatcher's `run_claude` is the place
  that would set it; **not needed for MVP** — noted here so the seam is obvious when you
  graduate.)
- What it buys: the observe → capture → fix flywheel this skill does by hand, productized —
  send a trace to a dataset in one click, define LLM-as-judge evaluators, run **online
  evals** on sampled live sessions, and use **annotation queues** for team review. Captured
  cases persist as regression datasets (the hosted form of `evals/`).

### 3. Langfuse — the self-hosted rung
Open-source, self-hostable observability with session tracing, annotation workflows, dataset
management, and evals. Reach for it when **data residency** or **self-hosting** is the
deciding constraint rather than turnkey convenience. OpenTelemetry-native instrumentation
(Traceloop/OpenLLMetry) is the standard way to feed it if you instrument beyond Claude Code's
own sessions.

## What does NOT change when you graduate

- **The source of session IDs stays the PR comment.** Even with LangSmith, the deterministic,
  dispatcher-posted PR table remains the contract `resolve-sessions.sh` reads; the hosted tool
  is an *additional* lens, not a replacement for the artifact.
- **The eval contract stays the repo-local `run-eval.sh`** (exit-0). A hosted platform can
  *also* hold datasets/evaluators, but the repo-local, framework-agnostic runner is what stays
  portable and version-controlled. Mirror, don't migrate, unless the team commits fully.
- **The write path stays `/learn`.** Observability tools observe; they never write the
  project's memory. Context fixes still land on a branch and reach `main` via merge
  (`stuck-forensics.md`).
