# Invariant discovery & promotion to lints

**Hackable seam.** How `/learn` surfaces the project's architectural invariants and
turns the best of them into mechanical checks — without overfitting.

## What a custom lint is

A lint is a program that reads the source and exits non-zero on a violation. A
*custom* lint is one you write — and the simplest, most language-agnostic flavor is
a short script in `scripts/lints/` wired into `scripts/local-checks.sh`. No linter
framework required: glob files, inspect their contents (grep or a parser), assert a
structural fact, exit 1 with a remediation message.

Two properties make custom lints the highest-value memory destination:

1. **The error message is a prompt.** Don't just say "violation" — say how to fix
   it. The failing lint feeds remediation straight into the agent's context, so it
   self-corrects with no human. A prose rule in AGENTS.md is advice the agent
   *might* follow; a lint is a rule it *cannot ship past*, plus the fix.
2. **It scales the way agents scale.** Once encoded, it applies to every file and
   every future PR at once.

## How to write a good lint

When you draft a lint, the message it prints on failure *is* the memory — it's the
prompt a future `/fix-local-checks` agent reads cold. Three things make it pull its weight.

**1. The message template.** Fill these in plain language:

- **WHERE** — file:line, or the offending pattern for a whole-repo/graph rule.
- **WHAT** — the violation as a fact about *this* code, not the rule in the abstract.
- **WHY** — one clause. Without it the agent satisfies the letter and breaks the intent.
- **FIX** — the concrete change to make (a short menu if several fixes are valid).
- **DON'T-CHEAT** — name the silencing trap for this rule.

Bad: `error: layering violation`. Good:

```
❌ repo/user.ts:12 imports from service/ (layer direction Types→Repo→Service→UI).
   WHY: layers compile bottom-up; a repo→service edge breaks build order.
   FIX: move the shared type to types/, or invert via a Provider interface.
   Don't silence with a path alias — that hides the same edge.
```

**2. Decide the fix path** — it maps onto the dispatcher's two-strike local-checks gate:

- **Autofixable + safe** (unique, semantics-preserving) → wire into
  `local-checks.sh fix`; the agent never spends a token on it.
- **Needs judgment** (several valid fixes, or the choice is semantic) → no autofix;
  the message must carry enough for `/fix-local-checks` to choose well.
- **Detect-only** (no mechanical fix) → still ship it; expect `/fix-local-checks`,
  or STUCK.

**3. Make it discriminating (match-as-proxy).** The lint's match is a *proxy* for the
problem, not the problem itself. Design it so the cheap way to satisfy it is also the
*right* way; if deletion or suppression would satisfy it, it's gameable — add a
companion guard (e.g. skip-detection guards test *removal*, which a plain "tests pass"
check would reward).

## Examples of lint-able invariants

- **Layer dependency direction** — "files under `repo/` may not import from
  `service/`." Walk imports; fail on a forward-violating edge.
  ```bash
  if grep -rEl "from ['\"].*/service/" src/repo/ ; then
    echo "❌ repo/ must not import from service/ (layer direction Types→Repo→Service→UI).
       Move the shared type to types/, or invert via a Provider interface." >&2
    exit 1
  fi
  ```
- **No raw SQL string interpolation** (injection class) — grep for interpolated SQL.
- **Structured logging only** — no `console.log(`/`print(` in `src/`.
- **Naming/format** — migration filenames match `^\d{14}_`.
- **File-size cap / public-API drift** — `wc -l` ceiling; exports match `openapi.yaml`.
- **Memory freshness** — `check-agents-md.sh` (AGENTS.md pointers exist) and
  `check-expert-links.sh` (Expert wikilinks resolve).

## What stays prose (NOT a lint)
Anything needing judgment: "is this the right abstraction?", "prefer composition
here." Those live in `pattern-<topic>.md` files in the Expert, or — if pre-emptively
load-bearing — AGENTS.md. The test: **if pass/fail is unambiguous, lint it; if it
needs taste, it stays prose.**

## The discipline (avoid overfitting)

A discovered "invariant" can be an incidental pattern, or a quirk of the current
model's failures rather than a real codebase property. So:

1. **Justify it.** In a single inline pass, write a one-line justification citing
   the diff hunk (file + line range) that motivated this rule. If you can't, drop
   it. This is the inline replacement for the old consensus gate — same bar,
   applied by the main agent.
2. **Prose first, lint on recurrence.** First sighting → record as a new
   `invariant-<rule>.md` (one rule per file) and flag a candidate lint. Same
   invariant seen across merges → promote to an enforced lint. One occurrence is
   a pattern; repetition is an invariant.
3. **Frame the *reason*.** "Repo→Service imports break the build because layers are
   compiled bottom-up" survives model upgrades; a bare prohibition doesn't.
4. **The drafted lint MUST pass current main.** Run it against the just-merged code
   before including it. If it reddens the merge it was born from, it's wrong — fix
   or drop it. (This is `/intent`'s right-reason check, inverted: it must *pass*.)
5. **Human disposes.** The candidate lands in the `learn/<sha>` PR; the human
   confirms before it becomes a blocking gate. Discovery proposes; the merge blesses.
