# Custom Linters for Agent Harnesses

A reference for designing deterministic checks that feed actionable error messages back to AI coding agents.

**Sub-reference for `lints.md`.** Load this before running the **category sweep** (lints menu #6)
or **linting the harness itself** (#7). `lints.md` carries the condensed A–K table; the depth —
mechanism, what each category misses, resolution path, silencing trap — is here.

The harness's job is to produce **closed, verifiable work** for the agent. Each linter rule is a sensor; each error message is a teaching moment. The detection mechanism is a spectrum (regex → AST → dependency graph → type system → runtime), and the resolution path splits along an axis that is the central design question of this whole document: **what can deterministic code fix, and what must the agent fix?**

---

## Table of Contents

- [The agent message skeleton](#the-agent-message-skeleton)
- [Per-rule attribute schema](#per-rule-attribute-schema)
- [The eleven categories](#the-eleven-categories)
  - [A. Formatting & Style](#a-formatting--style)
  - [B. Lexical / Textual Rules](#b-lexical--textual-rules)
  - [C. AST / Semantic Single-File Rules](#c-ast--semantic-single-file-rules)
  - [D. Architectural / Dependency-Direction](#d-architectural--dependency-direction)
  - [E. Naming & Structural Conventions](#e-naming--structural-conventions)
  - [F. Type-System / Contract Checks](#f-type-system--contract-checks)
  - [G. Grep-ability / Agent-Legibility](#g-grep-ability--agent-legibility)
  - [H. Security / Correctness Static Analysis (SAST)](#h-security--correctness-static-analysis-sast)
  - [I. Test & Coverage Invariants](#i-test--coverage-invariants)
  - [J. Context-File / Harness-Config Validation](#j-context-file--harness-config-validation)
  - [K. Logging / Observability Invariants](#k-logging--observability-invariants)
- [Cross-cutting patterns](#cross-cutting-patterns)
- [Concept reference](#concept-reference)
- [Resolution path summary](#resolution-path-summary)

---

## The agent message skeleton

Every linter message should fill the same seven fields, even when some collapse to nothing. The fields a category emphasizes or omits tells you what kind of category it is.

1. **Locus** — file + line/range + symbol, or (for graph categories) an edge or path.
2. **Rule identity** — stable ID the agent and any waiver/triage system can reference.
3. **What's wrong** — the violation as a fact about *this* code, not the rule in the abstract.
4. **Why it exists** — one clause. Stops the agent from satisfying the letter while breaking the intent.
5. **How to fix** — concrete remediation; often a menu of options when valid fixes diverge.
6. **Escape hatch** — if and how the rule may be waived, and the obligation that comes with waiving.
7. **Fix-applied flag** — if the linter already autofixed, the message says so. The agent's job becomes verify, not redo.

For categories with deferred or cross-file fixes (E, F, G, H, K), add:

- **Proposed action** — a concrete, ready-to-run codemod or rewrite with its blast radius (touch list).

For graph/dataflow categories (D, F, H, I3), add:

- **Path / cascade / counterexample** — the structural locus that distinguishes these from per-file rules.

---

## Per-rule attribute schema

When cataloging rules in a harness, track these columns for each rule:

| Attribute | What it captures | Why it matters |
|---|---|---|
| Category (A–K) | Conceptual kind of invariant | Drives where in the pipeline the rule runs |
| Detection mechanism | regex / AST / dependency-graph / type-system / runtime / filesystem | Drives cost and what's expressible |
| What it catches | Concrete failure modes | The agent-facing "what does this rule do" |
| When it runs | pre-commit / pre-push / CI / async / session-start | Cost vs. proximity to agent feedback loop |
| Resolution path | autofix / codemod (agent-triggered) / type-driven / agent-only / triage-only / sensor | The central deterministic-vs-AI axis |
| Error message shape | Which skeleton fields carry weight | Drives message authoring |
| False-positive risk | Low / medium / high | High FP → warn, don't block |
| Cost / latency | ms / seconds / minutes | Gates hot-path eligibility |
| Autofix safety | Safe / propose-only / unsafe | Per-rule, finer-grained than category |
| Determinism / idempotency | Stable across runs? | Required for gating |
| Grep-ability goal | Does the rule exist for future search? | Category G marker |
| Suppression granularity | Per-line / per-file / per-rule only | Affects how agent can escape |
| Rule generation | Hand-written or LLM-generated | Adoption pipeline |
| Beneficiary | Code-now / future-search / harness / operator / security | Drives "why" field framing |
| Match-as-proxy flag | Does the rule's match equal the bug, or just heuristically point at it? | If proxy → re-verify after fix |
| Sensor vs. gate | Block on every violation, or watch trend? | Some signals are more useful as trends |

---

## The eleven categories

### A. Formatting & Style

**Mechanism.** Parse to AST, re-print from scratch using fixed layout rules. The original whitespace, quotes, and line breaks are discarded. The defining properties: **total** (one canonical output per file) and **idempotent** (formatting already-formatted code changes nothing). That's what makes it safe on the hot path.

**Catches.** Whitespace, indentation, quote style, trailing commas, line wrapping, blank lines, import ordering, trivial textual fixers (trailing-whitespace, EOF newline, BOM, line endings).

**Misses.** Anything semantic. A formatter happily beautifies buggy code.

**When.** Pre-commit, earliest possible gate. Ordering note: lint `--fix` runs *before* the formatter, because lint fixes can output code that needs reformatting.

**Resolution.** Deterministic autofix, full stop. Unique fix, semantics-preserving, idempotent. **An agent should never spend a token on formatting.**

**Message.** Field 7 only ("fixed automatically, N files reformatted, no action required"). Add a clause: *"Do not re-edit for style; the formatter owns layout."* Without it, agents may try to "understand" or partially revert reformatting diffs.

**Silencing trap.** None — this is the only category without one.

**Edge case.** If the file doesn't parse, the formatter bails. Route the failure to the syntax-error path (C/F), not as a formatting message.

---

### B. Lexical / Textual Rules

**Mechanism.** Three sub-flavors:
- **Pure source-text regex** — grep over raw bytes. Cheapest, but blind to context.
- **Token/string-literal regex** — regex applied to a specific AST slot (e.g., import specifier). The sweet spot — regex matching anchored to a known node, so it doesn't false-positive on comments.
- **Node-shape selectors (ESQuery)** — drifts toward C; the upgrade path when raw regex gets brittle.

**Rule of thumb.** Raw text regex is fine for things that can't legally appear anywhere (a secret, a banned word in any context). The moment "it's OK in a comment but not in code" matters, anchor to an AST slot.

**Catches.** Banned imports/modules by name, banned global functions (`console.log`, `eval`), forbidden type names (`any`), secrets, missing license headers, leftover debug statements, `TODO` without ticket, deprecated API names.

**Misses.** Behavior. Catches the spelling, not the semantics — banning the *name* doesn't ban aliased or differently-named uses with the same effect.

**When.** Pre-commit. Fast — single pass, no type info.

**Resolution — the split.** The deciding question: **does the fix have a unique target?**
- **B1 — deterministic autofix.** Delete-type fixes (`console.log` removal), 1:1 mechanical replace (`var`→`let`), banned-type with a single canonical replacement.
- **B2 — agent-only.** Banned import needing a real substitute with different semantics (e.g., lodash default import → tree-shakable named imports — call sites must change). Hardcoded secrets (detection deterministic, fix requires moving to config/secrets manager).

**Message.** B1 collapses toward A (field 7 only). B2 needs the full skeleton — `WHY` stops the agent from switching to a different non-tree-shakeable form; `AUTOFIX: none` signals ownership.

**Silencing trap.** Coarse-grained suppression — some B-mechanisms (no-restricted-syntax) can only be disabled at whole-rule level, not per-line. Watch for over-suppression.

**Trap-flagging caveat.** Watch out for semantically-wrong `fixWith` autofixes — the replacement is only safe when it's semantically identical, not merely preferred.

---

### C. AST / Semantic Single-File Rules

**Mechanism.** AST visitor over a single file's tree. Two tiers:
- **Syntactic AST.** Tree shape alone, no type info. Complexity counting, banned constructs, hook rules. Hot-path eligible.
- **Type-aware AST.** Consults the type checker (e.g., `no-floating-promises` identifies values structurally as promise-like). More powerful, more expensive — usually stages later than syntactic rules.

**Decision tree for writing a custom rule.** Custom rules earn their place when you need one of four things: project-specific policy, nontrivial context, safe autofix/suggestions, or type-aware semantic checks. For pure "ban this syntax shape," reach for ESQuery selectors before writing a plugin.

**Catches.** Complexity/length thresholds, banned constructs, unsafe patterns (`any`, non-null assertions, floating promises), hook placement, switch-without-default. Also the *robust* version of B rules — AST-anchored "ban lodash default import" that sees the import node.

**Misses.** Anything cross-file. That's the hard ceiling and the reason D exists.

**When.** Syntactic: pre-commit. Type-aware: pre-push or CI.

**Resolution — three paths (the tooling encodes this).** ESLint's `meta.type` field gives you the routing:
- **C1 — `fix` (deterministic autofix).** Mechanical, semantics-preserving, unique. `prefer-const`, adding a missing generic. Re-run until stable: overlapping fixes drop one of the pair, so a single pass may leave residual violations.
- **C2 — `suggestion` (propose-only).** Likely fix but not provably safe; the message is a *menu*, agent chooses. `no-floating-promises` has four valid fixes (`await`, `.catch()`, `void`, `Promise.all`) and *which* is correct is semantic.
- **C3 — No fixer.** Complexity/length. Refactor into single-responsibility units; bounded escape hatch.

**Message.** C1 collapses to A. C2/C3 use full skeleton. Field 5 becomes a *menu*; field 4 (why) is load-bearing against the silencing trap. Routing can be driven directly off `meta.type` (`problem` / `suggestion` / `layout`).

**Silencing trap.** **`void` the promise** — satisfies `no-floating-promises` without handling the rejection. The cheap fix that silences the rule while preserving the bug. Suggestions and fixes should each be a single focused change; let A clean up layout afterward.

---

### D. Architectural / Dependency-Direction

**Mechanism.** Collect every import in the codebase into a directed graph (nodes = modules, edges = "imports from"). Then ask graph questions: is there a path X→Y? An edge in the wrong direction? A cycle? **The rule is a property of the graph, not a property of any file.**

This is the first category that can catch **indirect violations through chains**: `ui/` imports `utils/`, `utils/` imports `db/` — no individual import looks bad, but transitively `ui` reaches `db`, and the rule fires. No per-file rule sees this.

**Sub-flavors.** Layered (directional), forbidden edges (flat), allow-list (explicit allowed only), independence (peer modules no cross-talk), no cycles, containment/encapsulation (banned library only reachable through a designated wrapper).

**Catches.** Layer violations (UI→DB), forbidden cross-module imports, cycles, transitive leaks of sensitive libraries, missing encapsulation. The category that surfaces a lot of misplaced files on first adoption.

**Misses.** Dynamic imports, string-built import paths, DI containers, runtime reflection. Static analysis sees source.

**When.** Whole-repo analysis. Pre-push or commit pipeline — *not* per-keystroke. Critically: in CI only is too late for the agent loop. **If the agent sees "layer violation" in its feedback loop, it will fix the violation on the next iteration; if it only runs in CI after the PR, the agent never learns.**

**Resolution.** **Agent-only**, with one deterministic prep step: compute and surface the **shortest violating path** so the agent has full context. The fix itself is judgment work (refactoring, dependency inversion, file relocation, sometimes the rule was wrong) and frequently spans files. Cycle violations have a partial mechanical pattern (extract shared logic to a third module), but the cut is still judgment.

**Message.** Locus becomes an **edge or path**, not a file:line. Add a `PATH` field for indirect violations. `FIX` is a menu of refactor shapes. Anti-patterns must be called out explicitly — D rules are easy to satisfy by shape-shifting.

**Silencing traps.**
- **Widen the allow-list.** Erases the boundary instead of respecting it. Config edits to D rules should hit a separate review gate.
- **Route through a permitted intermediary.** Hides the same edge inside a "neutral" file.

**Attributes added.** Scope (file/edge/path), indirect-violation flag, config-edit gate.

---

### E. Naming & Structural Conventions

**Mechanism.** Mixed — and the mix has a reason:
- **Filesystem-level.** File name case, file location, extensions, file size. Pure path checks.
- **Symbol-name rules tied to AST node kind.** "Interfaces start with `I`," "hooks start with `use`," "type aliases are PascalCase." Needs the AST because the rule is "for symbols of kind X, name must match Y."
- **Structural placement.** "A `.tsx` file with JSX must be PascalCase *and* live under `components/`." Combines filesystem + AST. The rule opens and parses the file to decide which naming convention applies.

**Modern form.** Per-directory configuration via glob — the glob *is* the placement rule, the rule body is the naming rule.

**Catches.** File-name casing, filename-to-symbol agreement, prefix/suffix conventions (`use*`, `*Schema.ts`), placement violations, file size and line-count caps, directory-structure invariants (barrels required or banned).

**Misses.** Whether a symbol is *used* the way its name implies. E enforces spelling, not behavior — same gap as B.

**When.** Cheap checks pre-commit (filename case, file size, extension). AST-anchored ones pre-push. E rules trigger in *batches* when files move, so an "after refactor" gate beats per-edit.

**Resolution — four paths, including a new one.**
- **E1 — local rename (deterministic autofix, safe).** Local variable or non-exported type. Single file, AST replacement.
- **E2 — cross-file symbol rename (deterministic mechanics, agent-triggered).** Renaming an exported symbol mechanically. The *engine* is deterministic (TypeScript rename refactor, codemod) but the linter can't autofix it silently because the engine has blind spots (string-built imports, dynamic dispatch).
- **E3 — file moves/renames (deterministic mechanics, agent-triggered).** Same shape as E2. Can break build configs, deploy scripts, generated artifacts.
- **E4 — propose-only (file size).** Genuine judgment — which boundaries? Bounded escape hatch.

**The new resolution path.** E introduces **deterministic-fix, agent-triggered**: the tool *generates* the codemod with its blast radius, the agent decides whether to run it. Not autofix (linter applies it); not agent-only (agent invents it).

**Message.** Adds `PROPOSED ACTION` block with the touch list and codemod invocation. Adds a `rule scope` field so the agent doesn't fix-by-moving-out-of-scope.

**Silencing trap.** **eslint-disable a placement rule** — the cheap suppression for naming conventions because the violation doesn't reflect a runtime bug.

**Attributes added.** Blast radius, computed target state, rule scoping (per-glob).

---

### F. Type-System / Contract Checks

**Mechanism.** Not really linting — running a separate analysis engine (the type checker, or a runtime schema parser) and ingesting its diagnostics as messages. The mechanism is **type inference + flow analysis**, the inverse of pattern matching: rules emerge from types rather than being authored.

Two sub-mechanisms:
- **F1 — Static type checking (tsc, mypy).** Compile-time. Sees only what's written.
- **F2 — Runtime schema parsing (Zod, Pydantic).** Runtime. Validates actual data at trust boundaries.

These are **layered defenses**, not redundant. F1 proves the code is internally consistent. F2 proves the data entering the code matches what F1 was proven against. *Validate trust boundaries, type-check everything else.*

A useful F-flavored architectural rule (cross-category with D): **every external input must pass a schema parse before being typed**. Bans `unknown` leaking past designated parse points.

**Catches.**
- **F1.** Mismatched argument types, missing/extra object properties, null/undefined leaks, exhaustiveness gaps in discriminated unions, unsafe casts, `any` propagation.
- **F2.** Malformed payloads from APIs, forms, env vars, message queues. Violations F1 *cannot* see.

**Misses.** Behavior. Correct type signatures don't guarantee correct functions.

**When.** Inner loop: incremental tsc on save. Pre-push/CI: full project tsc, no cache, authoritative. F2 runs at runtime; the lint-level concern is presence at boundaries.

**Resolution — the type-driven path (distinct from autofix and agent).**
- **F3 — Type-driven deterministic.** tsc says "Property `email` is missing in type X" — the fix is computable. Modern LSPs expose this as "quick fix." For an agent: high-confidence mechanical edit given the tool's output.
- **F4 — Type-driven, agent judgment.** `Type 'string | undefined' is not assignable to type 'string'` has four valid fixes (guard, default, assert, widen). The type checker localizes the problem deterministically; resolution is semantic.
- **F5 — Cascade.** F2 schema edit → F1 re-check enumerates *every* downstream site that needs to change. The cascade *is* the agent's task list.

**Message.** Preserve the tool's exact wording in a `RAW` field — agent can use the diagnostic code (`TS2322`) to look up canonical handling. The harness's job is *enrichment*: add `WHY` and the `FIX menu with traps flagged`. For F5, render the cascade as the locus.

**Silencing traps.**
- **`!` and `as` assertions** — silence the checker, don't address the issue. Will surface as a runtime crash.
- **`@ts-ignore` / `# type: ignore`** — same trap, comment form.
- **Weakening tsconfig strictness** — erases the rule across the whole codebase. Treat config changes to strictness flags like D's allow-list edits: separate gate.

**Attributes added.** Tool-as-source-of-truth, cascade-aware, strictness profile (dial, not on/off).

---

### G. Grep-ability / Agent-Legibility

**Mechanism.** Mostly category C (AST visitor), occasionally B (textual import checks), occasionally D (import graph for absolute-vs-relative). Mechanism unremarkable; **rationale** is what makes it a distinct category.

**Defining test.** Does removing the rule make the program incorrect, or just harder to navigate? If incorrect → C/D/F. If just harder to navigate → G.

Every G rule is justified by some variant of "so future search/refactors work." The eslint-plugin-import docs are explicit: *"ensuring that default exports are named helps improve the grepability of the codebase by encouraging the re-use of the same identifier."*

**Catches.** No anonymous default exports, no default exports at all, absolute imports over relative, barrel discipline (require or ban — pick one), consistent error/result types, explicit DTOs at boundaries. Underlying pattern: **prefer the form that puts a stable, distinctive identifier at every relevant site.**

**Misses.** Any actual bug. A codebase perfectly violating every G rule still runs correctly. The cost is diffuse and surfaces later — but later, the cost is now the *immediate* cost of the next agent task failing to find things.

**When.** Same as C/E. Unusually amenable to **one-shot retroactive runs** — adopt a G rule on an existing codebase, generate a batch of violations, pay them down with a codemod.

**Resolution — the narrowest profile in the list.** Almost everything is E2/E3 (deterministic-fix, agent-triggered):
- **Single-file safe autofix.** Adding a name to an anonymous default export.
- **Codemod with review.** Default→named exports, relative→absolute imports, symbol renames. The mechanics are determined; the touch surface is wide.
- **Rare agent-judgment.** Choosing what name to give an anonymous default when the filename doesn't supply one.

**Message.** Short, but field 4 (`WHY`) is unusually load-bearing because the cost is delayed and invisible. Without explicit framing of the future cost, agents rationally suppress.

**Silencing trap.** **`eslint-disable` the comment** — because G violations don't reflect a present-tense bug, suppression *feels* low-cost. The message must counter this: "this isn't a bug now; it's an obstacle for the next task that needs to find this symbol."

**Bonus pattern.** G is the category most amenable to **agentic rule generation**: spot drift, draft a rule with autofix and tests, run codemod across repo, put on hot path.

**Attribute added.** Beneficiary — present vs. future. G rules serve the future agent/human doing the next task.

---

### H. Security / Correctness Static Analysis (SAST)

**Mechanism — three escalating tiers.**
- **H1 — Syntactic pattern matching.** "Find calls to `eval`," "string concat into SQL." Cheap, blind to context.
- **H2 — Cross-file dataflow / taint analysis.** Track values from sources (user input) to sinks (DB queries, HTML), verifying sanitizers on every path. Same family as D (graph reachability), but the graph is dataflow.
- **H3 — Pattern + LLM contextual triage.** Detection deterministic, LLM filters false positives by reading context the static analyzer can't see (dead code paths, framework protections, test fixtures, organizational sanitizers).

**The big mechanism story.** The industry has converged on **hybrid** because neither approach alone works: LLM-only IDOR detection produced 88% false positives; pure SAST misses business-logic vulnerabilities. Hybrid pipelines hit ~90% precision vs. ~36% for SAST alone and ~66% for GPT-4 alone.

**H is the first category where the production answer is openly "use both deterministic and LLM, in distinct roles."** Detection deterministic. Triage and remediation LLM-assisted.

**Catches.** SQL injection, XSS, command injection, path traversal, SSRF, insecure deserialization, weak crypto, hardcoded secrets, unsafe regex (ReDoS), open redirects, **and** (with H3 only) IDOR, broken access control, missing authn/authz checks.

**Misses.** Anything the analyzer can't see paths to. Runtime config, dynamic loading, third-party code (that's SCA, an adjacent discipline). Doesn't know finding *priority* without help — severity × asset context.

**When.** Cheap H1 in inner loop (pre-push, blocking). H2/H3 **asynchronous** — taint analysis takes minutes; LLM triage is too token-expensive per commit. Surface as PR comments. **Treating them as one "security check" forces a compromise wrong at both ends.**

**Resolution — explicit pipeline.**
1. Deterministic detection.
2. Deterministic enrichment — taint mode produces the dataflow path.
3. LLM-assisted triage — filter false positives.
4. LLM-assisted remediation — fix proposal informed by the path.
5. **Deterministic re-verification** — run the rule against the proposed code; if it still matches, the fix is fake.

Resolution paths:
- **H-A — Deterministic fix, mechanical (rare).** `Math.random()` for security → `crypto.randomBytes`. Codemod-able.
- **H-B — Context-dependent, agent judgment.** Most cases. SQL injection's "correct fix template" (parameterized queries) but the edit depends on the ORM.
- **H-C — Architectural change.** Missing authorization. Spans D-shaped questions (which layer owns this check?).
- **H-D — Triage-only.** Finding is a false positive. The resolution is *marking with reasoning that feeds future auto-triage* (e.g., Semgrep Memories).

**Message.** Most enriched in the list. Adds severity, **reachability** (exploitable / theoretical / dead / test), **dataflow path** (source → sanitizer? → sink), **triage classification**. Two distinct anti-patterns must be flagged.

**Silencing traps.**
- **Satisfies-the-match trap.** Hand-rolled escape, code reshape that no longer matches the rule pattern but doesn't fix the bug. Semgrep's own docs warn: "the code must be updated so the Semgrep rule pattern no longer matches it" — the match is a *proxy*, not the bug itself.
- **Fixes-locally-but-propagates trap.** Validate upstream, leave the bad pattern. Works *here*, propagates the unsafe shape — and reviewers/agents may copy it elsewhere.

**Match-as-proxy.** Every H rule has this property. The rule's match is a heuristic for the vulnerability, not its definition. **Requires post-fix verification** — run the rule against the new code.

**Attributes added.** Reachability, triage state, match-as-proxy, severity × asset context.

---

### I. Test & Coverage Invariants

**Mechanism — the only dynamic category in the list.** Runs the code and observes behavior. Three sub-tiers:
- **I1 — Coverage on changed lines.** Run tests with instrumentation, intersect executed lines with git diff, fail if ratio drops. Cheap.
- **I2 — Structural test presence.** Filesystem + light AST: does a test file exist for this symbol/route? (Essentially J wearing test clothes.)
- **I3 — Mutation testing.** Run the suite against altered code. Survived mutant = test-suite blind spot. Killed mutant = suite catches that class of bug. Vocabulary inverts: killed = good.

**Why coverage isn't enough.** Coverage can be 95% with tests that don't assert meaningful behavior. The mutation testing literature documents this repeatedly. **Agents are uncannily good at writing tests that pass without testing anything** — mocking out the function under test and asserting the mock was called. Mutation testing is the sensor that catches this.

**Catches.** Untested new code (I1), missing test files (I2), tests that execute code without genuinely asserting (I3).

**Misses.** Bugs the suite can't detect anyway. I measures the *tests' fitness*, not the code's. Also: **equivalent mutants** — mutations that don't change observable behavior — show up as "survived" but can't be killed. Same noise problem as H false positives.

**When.** I1/I2: inner loop fine. I3: **never on the hot path**. Run incrementally on changed code at pre-PR, full runs periodically (nightly/weekly) on critical modules. Mutation testing is more useful as a **trend sensor** ("orderProcessor's mutation score dropped from 78% to 61% this month") than a blocking gate.

**Resolution.** **Agent-only**, with a unique property: the **locus is shifted**. Violation in source, fix in tests.

Sub-paths:
- **I1.** Write the missing test. Tool tells the agent exactly which lines are uncovered.
- **I2.** Create the missing test file. Scaffold deterministically, content is agent work.
- **I3.** Write a test that distinguishes original from mutant. **The mutant is a near-derivable test specification** — the highest-leverage signal in the list.

**Escape hatch is a budget, not per-rule suppression.** Mutation score thresholds (high/low/break). Not every mutant is worth killing; equivalent mutants and incidental code paths can be excluded with rationale.

**Message.** I3's structure is unique: `ORIGINAL`/`MUTANT` as paired fields (the diff is the locus), `COVERING TESTS` (which existing tests ran and didn't catch it), test scaffold in the autofix slot.

**Silencing trap.** **Implementation-asserting tests.** "Kill this mutant" → agent mocks everything around the line and asserts it's called. Mutant killed, test is brittle and tests nothing real. Looks fine until refactoring breaks it for the wrong reason.

**Attributes added.** Locus-shifted, sensor-vs-gate, counterexample-bearing.

---

### J. Context-File / Harness-Config Validation

**The meta-category.** Linters that lint the harness itself. Smallest in scope, possibly highest in leverage — if J fails, every other category's signal becomes unreliable, because the harness's machinery may be misconfigured.

**Mechanism — the cheapest in the list.**
- **J1 — Filesystem existence.** `fs.existsSync`, `which`. Does the file/binary/script the harness references exist?
- **J2 — Config schema validation.** JSON Schema, YAML schema, Zod. `package.json`, `tsconfig.json`, agent definition frontmatter.
- **J3 — Cross-reference.** Does the `npm` script `CLAUDE.md` names exist in `package.json`? Two-document parse + lookup.

The mechanism distinction worth being explicit about: **J never runs anyone's code, never reasons about runtime behavior, never needs the type checker.** Lowest false-positive rate in the list — the facts it checks are unambiguous.

**Catches.**
- Dead references in context docs.
- Malformed YAML frontmatter, invalid JSON.
- Phantom script/tool names.
- **Harness-platform limits** — entry files over the context-window character limit, files over the platform's read limit, slow pre-commit hooks that hang sessions. Platform-specific footguns the team didn't know existed.

**Misses.** Content quality of context documents. CLAUDE.md can be syntactically valid with every reference resolving and still be terrible advice. J validates form, not meaning. Layer a prompt-based check on top if needed.

**When.** Pre-commit *only when harness files changed*. **At agent session start** (the underappreciated slot — broken references silently degrade the agent's mental model at the moment they cost the most). CI as always-on guardrail.

**Resolution — the cleanest deterministic profile in the list.**
- **J-A — Safe autofix.** Moved-file reference (fuzzy match the new path), trailing-comma JSON, dead `.gitignore` paths.
- **J-B — Propose-only.** Phantom script — could mean several real scripts; agent picks. Missing referenced file — was the reference stale, or was the file mistakenly deleted?
- **J-C — Agent-only.** Platform-limit violations (CLAUDE.md too long → rewrite). Schema mismatch on custom fields.

**Message.** Short. Adds a **`HARNESS IMPACT`** field — describes what the agent will fail to know or do because of the misconfiguration. No other category needs this; the agent isn't the user of any other rule's output.

**Silencing trap.** **Silence the reference rather than restore what it pointed to.** Delete the broken-reference line from CLAUDE.md — rule passes, but the agent silently loses context it was supposed to have. The harness has decayed; the rot has been hidden. Structurally different from other categories' traps: the silenced thing was *information the agent needed*, not a constraint it had to respect.

**Second J-trap.** **Loosen J's own validation.** Cheap meta-fix — edit the validator so it stops checking the broken thing. Treat edits to J rules themselves with extra scrutiny — there's no outer harness to catch this rot.

**Attributes added.** Reflexivity (constrains the harness, not the application), harness-impact statement.

---

### K. Logging / Observability Invariants

**Mechanism.** Borrows from earlier categories with a unified intent. The intent is what makes K its own category: **make log output queryable for the future operator at 3am.**

Sub-mechanisms:
- **K1 — Banned logging primitives.** B-shaped: `console.log`, `print`, raw `fmt.Println`.
- **K2 — Required logger shape.** C-shaped: AST visitor over logger calls, checking that arguments conform to the structured shape `logger.<level>({ fields }, '<event-name>')`.
- **K3 — Import discipline.** D/G-shaped: logger imported from the canonical module, never instantiated locally.
- **K4 — Required logging at boundaries.** E-shaped: every API route has an entry log, every job has a completion log.

**Defining property.** K's contract counterparty is a **system outside the codebase** (the observability platform) and a **future user other than the code-reader** (the operator running queries). Kinship with G (future-search) but a different beneficiary.

**Catches.** Unstructured log calls (string concat → unqueryable), missing correlation/trace IDs, stray `console.log` / `print` from agent debugging, logged secrets/PII, inconsistent log levels, required-call gaps (handler with no entry log), naming inconsistency (`user_id` vs `userId` vs `uid` for the same value).

**Misses.** Whether the log is *meaningful*. "thing happened" with no useful fields satisfies every shape rule.

**When.** K1/K3 pre-commit. K2 pre-push (full project scan). K4 most useful as I-style coverage sensor — "ratio of handlers with proper entry logs over time."

**The unusually fast-learning property.** K rules are learned by LLMs in fewer iterations than any other category — one iteration in a documented case study. The violations are local, the fix shape is uniform across the codebase, and the message can hand the agent a literal template.

**Resolution — heavily autofixable.**
- **K-A — Safe autofix.** Stray `console.log` → delete, `console.error(e)` → structured equivalent (when convention is known), missing logger import.
- **K-B — Codemod / agent-triggered.** Bulk `console.*` → structured calls. The codemod handles the call-site rewrite, the agent fills in the fields.
- **K-C — Agent-only.** Adding meaningful logs where there are none (shape mechanical, content judgment). PII-aware field selection.
- **K-D — Sensor.** K4 trends.

**Message.** Carries a **conventional-shape template** as a field, not embedded in prose. The agent has an unambiguous target.

**Silencing traps.**
- **Delete-the-log trap.** Fix "this handler has no entry log" by deleting the rule rather than adding the log. Or fix "log is unstructured" by removing the log entirely.
- **Drop-the-field trap.** "All logs need correlation_id" → drop `correlation_id` from the call when the value isn't conveniently in scope, instead of threading it through.
- **Log-everything trap.** "This handler needs logs" → log every variable. Satisfies coverage, generates spew, trains operators to ignore the channel.

**Attributes added.** Conventional-shape template, external-system contract.

---

## Cross-cutting patterns

Three patterns showed up so consistently across categories they're principles, not category attributes.

### 1. Every category has a silencing trap

The cheap fix that satisfies the rule while erasing its purpose. Naming this trap *in the rule's message* is the single most repeatable harness-design move.

| Cat | Trap |
|---|---|
| A | none |
| B | semantically-wrong `fixWith` autofix |
| C | `void` the promise (or analog) |
| D | widen the allow-list; route through an intermediary |
| E | eslint-disable the placement rule |
| F | `!` / `as` / `@ts-ignore` / weaken tsconfig |
| G | suppress the comment |
| H | hand-rolled escape; fix-locally-but-propagates |
| I | implementation-asserting tests |
| J | silence the reference; loosen J's own validation |
| K | delete the log; drop the field; log everything |

A common shape: **the silencing trap is whatever satisfies the rule's *match* without addressing the rule's *intent*.** In some categories the match is a near-proxy for the intent (A, B1); in others (D, H, K) the gap is wide and exploitable.

### 2. "Deterministic-fix, agent-triggered" is the workhorse path

Not silent autofix, not agent-only — the most common resolution shape is: **the linter generates a codemod or proposed action with its blast radius; the agent decides whether to run it.** E, F (cascade), G, H (proposed fix with re-verification), J, K all lean here.

**The agent's contribution is small but real** — knowing things the codemod's AST view can't see (CI workflows that grep for paths, deploy scripts that hardcode names). The codemod's contribution is the 95% bulk-mechanical part. Neither alone scales.

This is also the answer to the deterministic-vs-AI framing: most fixes are *executed* by deterministic code; the agent is the *trigger* and *reviewer*, not the *transformer*.

### 3. Three categories produce near-derivable fix specifications

Most rules say "this is wrong, figure out the fix." Three categories produce a *specification* of the fix:

- **F's cascade** — the type checker enumerates every downstream site that needs to change.
- **H's dataflow path** — source → sanitizer? → sink, localized to the smallest correct mental model.
- **I3's surviving mutant** — the test that distinguishes original from mutant is nearly derivable from the mutant's diff.

These convert open-ended agent work into bounded, verifiable work. **The harness should treat these signals as first-class** — they're not just messages, they're closed task definitions.

### 4. The "delayed-cost categories" cluster (G, J, K)

Three categories have a structural property the others don't: **the beneficiary of the rule isn't the agent now, but someone later.**

- G — future code-reader / future agent task.
- J — agent itself at session start (silent harness rot).
- K — future operator running queries.

These all produce *silent failures at edit time* — no build error, no test failure, no runtime crash. Agents rationally deprioritize them against louder violations. **The messages in these categories must work harder on field 4 (`WHY`) to surface the delayed cost**, or suppression will be the agent's default move.

### 5. The "match-as-proxy" property

Every H rule has it explicitly; some C and K rules have it implicitly. The rule's match is a *heuristic* for the underlying intent, not its definition. **Rules with this property require post-fix verification** — re-run the rule against the new code; if it still matches, the fix is fake.

Worth tracking as a per-rule attribute, not just an H category property.

---

## Concept reference

Short definitions of recurring terms.

**AST (Abstract Syntax Tree).** The structural representation of source code after parsing. Every code element becomes a node with a type, attributes, and children. *Not* the call graph. A linter "visits" the tree and asks structural questions; a regex sees raw text.

**Codemod.** A program that rewrites code by manipulating its AST, applied across many files in one run. Different from autofix (linter applies it silently) and agent edit (LLM invents it). The codemod is deterministic; the *invocation* may be agent-triggered.

**Autofix.** The linter's own `--fix` channel. Small, safe, idempotent transformations the rule author shipped alongside the rule. Runs automatically.

**Suggestion.** A proposed edit that is *never* auto-applied; surfaced for a human or agent to choose. ESLint's explicit distinction from autofix.

**Type-driven resolution.** The fix is produced by the type checker's own output — the tool localizes the problem and often produces a complete plan (the cascade). Distinct from autofix (the linter applies it) and agent-only (the agent invents it).

**Taint analysis.** Track values from sources (untrusted input) to sinks (security-sensitive operations), checking for sanitizers between. The cross-file dataflow tier of SAST.

**Mutation testing.** Make small changes to the code (mutants); run the test suite; check if tests catch the change. Survived = test gap. Killed = test catches that class of bug.

**Architecture fitness function.** An automated test that enforces an architectural invariant — dependency direction, layer boundaries, encapsulation. Runs in the same pipeline as tests and linters.

**Grep-ability.** The property of a codebase that distinctive symbol names reliably point to single locations. Optimized for by category G rules so future search (and refactoring) works.

**Trust boundary.** The interface between a system you control and one you don't (network, file upload, message queue, env vars). External inputs must be parsed at boundaries before being typed.

**Silencing trap.** The cheap fix that satisfies a rule's *match* without addressing its *intent*. Every category has at least one; naming it explicitly in messages is a key harness design move.

**Match-as-proxy.** The property that a rule's pattern match is a heuristic for the underlying problem, not its definition. Rules with this property require re-verification after the fix.

---

## Resolution path summary

The deterministic-vs-AI question, distilled. Each row is a *resolution path*, not a category.

| Path | Who executes | Who decides | Categories that use it |
|---|---|---|---|
| Silent autofix | linter | linter (rule author already decided) | A; B1; C1; E1; J-A; K-A |
| Suggestion menu | linter proposes | agent picks by intent | C2; F4; H-B |
| Deterministic-fix, agent-triggered | codemod / rename engine | agent (after reviewing touch list) | E2/E3; F3 (partial); G (most); H-A; J-B; K-B |
| Type-driven cascade | type checker enumerates plan | agent executes each item | F5; H2 (path enumeration) |
| Agent-only refactor | agent | agent (full judgment) | C3; D; F4 (config-shape); H-C; I (all); K-C |
| Triage-only | LLM classifies, agent confirms | agent / human | H-D |
| Sensor (trend) | tool emits over time | harness decides on threshold | I3 trends; K4 trends; D drift detection |
| Reflexive / config-gated | edits to the rule itself | requires elevated review | D allow-list; F tsconfig; J's own rules |

The harness's leverage comes from **pushing as much fix execution as possible into the top rows** (deterministic) and spending agent tokens only on the judgment of *whether and when* to apply them. The agent is the trigger and reviewer; deterministic code is the transformer.
