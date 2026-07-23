---
name: spec-validate
description: Validates a mainspec and its slices via 3-subagent consensus plus expert review, then *applies* impactful fixes directly to the spec files. No human-in-the-loop summary or approval — agent-first. Touches `specs/<feature>/.validated` as its final committed action.
---

# Spec Validate

Validate a mainspec and its slices using parallel foreground subagents for high-confidence issue detection, then **apply the impactful findings as fixes directly to the spec files**. Agent-first: no human-in-the-loop. Invoked headless by the harness dispatcher, walks the consensus → classify → fix → sentinel protocol, and exits.

## Invocation Contract

**Invoked by the dispatcher as:** `claude -p "/spec-validate <feature>"`, run from inside the feature worktree (the dispatcher `cd`s into it — there is no print-mode `--cwd` flag).

**Single argument:** `<feature>` — kebab-case feature slug.

**Inputs read from disk (paths relative to cwd):**
- `specs/<feature>/mainspec.md`
- `specs/<feature>/slices/*.md`
- The codebase (subagents ground findings in actual code).

**Outputs to disk:**
- Edits to `specs/<feature>/mainspec.md` and/or `specs/<feature>/slices/*.md` for impactful findings.
- `specs/<feature>/validation-log.md` — audit trail: all consensus findings, classification (impactful vs. nitpick), and which fixes were applied. For observability; not load-bearing for the dispatcher.
- `specs/<feature>/.validated` (empty sentinel).

**Completion protocol (in order):**
1. Run 3-subagent consensus + expert review (Phases 1–2 below).
2. Classify each 3/3 and 2/3 finding as **impactful** or **nitpick** (Phase 3).
3. For each impactful finding: edit the affected mainspec or slice file in place.
4. Write `specs/<feature>/validation-log.md` capturing every finding, classification, and what was changed.
5. `git add` all changes (edited spec files + validation-log.md), commit, push.
6. `touch specs/<feature>/.validated`.
7. `git add` the sentinel, commit, push.

The sentinel is the **final** commit-and-push action. The dispatcher uses only the sentinel to advance to implementation.

**Idempotency:**
- If `specs/<feature>/.validated` already exists, exit immediately.
- If `specs/<feature>/mainspec.md` does not exist, exit silently — the dispatcher's state machine should not have fired this skill yet; planning has not completed.
- If validation-log.md exists but the sentinel does not (crash mid-write), the dispatcher's worktree wipe will discard any uncommitted log changes, so we re-run validation from scratch. Acceptable cost.

---

## Phase 1: Spawn Validation Agents

Spawn **3 parallel subagents** (always 3 — this is the agent-first default, no runtime override) to independently review the spec. Each agent gets the same prompt and reviews independently — consensus on issues indicates higher confidence. Only give file paths to the subagent (mainspec.md plus each slice file).

### Spawn Agents in Foreground (Parallel)

Spawn all 3 agents **in parallel in a single message** using the Task tool. Do **NOT** use `run_in_background`. All agents run concurrently and return summarized results automatically.

```
Task(
  description="Spec validation A",
  subagent_type="general-purpose",
  model="opus",
  prompt="[Validation prompt below with spec content inserted]"
)

Task(
  description="Spec validation B",
  subagent_type="general-purpose",
  model="opus",
  prompt="[Identical prompt]"
)

Task(
  description="Spec validation C",
  subagent_type="general-purpose",
  model="opus",
  prompt="[Identical prompt]"
)
```

All three agents execute concurrently and return summarized findings directly.

### Validation Prompt

Each agent receives this prompt (insert the actual spec content):

~~~
Do you see any flaw in this spec plan? Starting from the mainspec to its corresponding slices. Do you see any gap in logic or anything that was missed?
Ground your answers in the actual codebase referenced in the spec.

## Spec to Validate

**Mainspec Path:** [path]

**Slices:**
[For each slice, insert file path to slice]

## Output Guidance
For each issue include: which slice/section, codebase file path / line numbers, what the problem is, and suggested fix if possible.
~~~

**Wait for all agents to return their summaries before proceeding.**

---

## Phase 2: Expert Review

After subagent results are collected, perform an expert validation pass. This happens after Phase 1 so you can focus expert review on areas the subagents flagged.

### Read the Spec Content

Read the mainspec and slice files to understand the spec content for expert consultation.

### Consult Relevant Experts

Expert skills are named `expert-*`. Based on the spec content, identify which experts apply and invoke them:

1. **Discover Available Experts** — Use `ls .claude/skills/ | grep expert` (do not use Glob, as it may not resolve symlinks).
2. **Identify applicable experts** — Look at the spec content and determine which `expert-*` skills are relevant.
3. **Invoke relevant experts** — Use `skill: "expert-*"` to get domain-specific validation guidance.

### Expert-Informed Review

With expert context, review the spec for domain-specific issues:
- Framework-specific anti-patterns
- Internal library misuse
- Security concerns
- Infrastructure/deployment issues

**Collect expert findings** — Keep track of any issues identified during expert review. These are merged with subagent findings in Phase 3.

---

## Phase 3: Classify Findings and Apply Fixes

This is where spec-validate diverges from a human-facing validator: we do not summarize and present consensus to a user. We classify findings ourselves and apply impactful ones directly as edits to the spec files.

### 3a. Deduplicate

Two findings are "the same" if they:
- Reference the same slice/section AND
- Identify the same fundamental problem (even if worded differently).

Apply deduplication across all 3 subagent findings + expert findings.

### 3b. Filter to consensus

Group deduplicated findings by how many subagents identified them:

| Consensus | Confidence |
|-----------|------------|
| 3/3 found | Very High |
| 2/3 found | High |
| 1/3 found | Medium |

**Discard 1/3 findings.** They are low-confidence and not worth automatic application. Only 3/3 and 2/3 findings, plus expert findings flagged as blocking by the expert, are candidates for fixing.

### 3c. Fix Classification

For each candidate finding, classify as **impactful** or **nitpick**:

- **Impactful** — Would mislead the implementing agent. Examples:
  - Missing or wrong type contracts (interfaces, schemas)
  - Incorrect BEFORE/AFTER file paths
  - Ambiguous final-slice Success Criteria (no clear PRD-test command)
  - Missing forward-looking requirements that block downstream slices
  - Security gaps in DO/DON'T examples
  - Wrong file path references
  - Missing slice dependency in the Dependency Map
  - Broken slice DAG (cycle, dangling reference)
  - Slice that contradicts the PRD's definition of done
  - Final slice missing Success Criteria (must invoke `./prds/<feature>/run-prd-test.sh` and require exit 0 as the PRD-completion criterion)

  **→ Apply the fix.**

- **Nitpick** — Would not change implementation outcomes. Examples:
  - Spelling, wording polish, redundant phrasing
  - Minor style preferences
  - "Nice-to-have" additional examples when one already exists
  - Cosmetic Mermaid color suggestions
  - Reordering equivalent items in a list

  **→ Skip the fix, log the finding.**

When in doubt, ask: *would an implementation agent reading only this spec produce different code if this finding were addressed?* If yes → impactful. If no → nitpick.

### 3d. Apply Impactful Fixes

Edit the affected mainspec and slice files directly. Use the Edit tool. For each fix:
- Preserve all unrelated content.
- Apply the suggested fix from the finding (or a better fix if the finding is directionally correct but imprecise — you have the full context the finding does not).
- Note in `validation-log.md` what was changed and why.

If a finding lists multiple possible fixes, pick the one most consistent with the rest of the spec and the codebase patterns.

### 3e. Write `specs/<feature>/validation-log.md`

Structure:

```markdown
# Validation Log: <feature>

## Subagent consensus

### 3/3 (Very High Confidence)
- **[Applied]** Slice 1.2 / Success Criteria — finding text — fix applied: <description>
- **[Skipped: nitpick]** Slice 2.1 / Wording — finding text — reason for skip

### 2/3 (High Confidence)
- **[Applied]** ...
- **[Skipped: nitpick]** ...

### 1/3 (Discarded)
- Slice X.Y / ... — finding text — discarded (low confidence)

## Expert findings

- **[Applied]** [Expert: react-expert] Slice 2.3 — finding text — fix applied: <description>
- **[Skipped: nitpick]** ...

## Summary
- Total findings: N
- Impactful fixes applied: M
- Nitpicks skipped: K
- Discarded (1/3): L
```

### 3f. Commit and Sentinel

After all edits and the log are written:

```bash
git add specs/<feature>/
git commit -m "spec-validate: applied <M> impactful fixes to <feature>"
git push

touch specs/<feature>/.validated
git add specs/<feature>/.validated
git commit -m "spec-validate: sentinel for <feature>"
git push
```

The sentinel must be the **final** commit-and-push — only after all artifacts are in place. The dispatcher uses only the sentinel to advance.

---

## Notes

- **Always 3 subagents** — Agent-first default; no runtime override. The harness doc fixes this at 3 for consistency.
- **Model: opus** — Use opus for high-quality validation reasoning.
- **Foreground parallel execution** — All subagents run concurrently in a single message and return summarized results directly.
- **No rigid output schema for agents** — Let them find issues naturally; classification happens in Phase 3.
- **Consensus = confidence** — Issues found by multiple independent agents are more likely real.
- **Expert review after subagents** — Expert review runs after subagent results are in, allowing experts to focus on flagged areas.
- **All fixes applied without HITL** — Impactful 3/3 and 2/3 findings are applied automatically. Nitpicks are logged but never applied.
- **No loop-back to spec-planning** — spec-validate is the last spec-layer step. The dispatcher's state machine walks forward only.
- **Single consolidation point** — All deduplication, classification, and fix application happen once, after all reviews complete.
