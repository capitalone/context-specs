# Probe recipes — building `measure-outcome.sh`

`measure-outcome.sh` is the executable instrument. It reads the metric from the live world
and **prints a single current value** (plus, ideally, a one-line provenance note to
stderr). `/roadmap` runs it once to capture the baseline; `/evaluate-outcome` re-runs the
*same* probe as a sensor over the horizon — it never re-generates it (synthesize once, read
many). You draft it; the human reviews (R8).

Unlike `run-prd-test.sh`, the probe is **not** a pass/fail gate. Its exit code signals only
*could I read the metric?* — `0` = a reading was produced (printed to stdout), non-zero =
the instrument couldn't read (no access, no data). The **value** is the payload, not the
exit code. Nothing downstream merges or blocks on it.

## Shape

```bash
#!/usr/bin/env bash
# Instrument for <metric-slug>. Prints the current value to stdout.
# Read-only against the live world. Exit 0 = a reading was produced.
set -euo pipefail

# Access by POINTER, never a secret in this file:
: "${DATABASE_URL_READONLY:?set DATABASE_URL_READONLY (read-only replica)}"

# ... read the metric ...

echo "$value"                      # stdout = the payload (e.g. "31%" or "0.31")
echo "source: <what was read>" >&2 # stderr = provenance, for the human and the log
```

- **Read-only, always.** A probe never writes to the product. Use read replicas, read
  scopes, exported transcripts — never a credential that can mutate.
- **Access is a pointer.** Require an env var (`${VAR:?…}`) or name the human step ("export
  from Amplitude to `metrics/<m>/export.csv` first"). Never commit a secret.
- **Print one value to stdout.** Keep the payload a single, parseable number/percentage so
  `readings.log` stays a clean time-series. Everything else goes to stderr.
- **Self-contained.** Anything the probe reads (a `query.sql`, a judge `rubric.md`, an
  exported CSV) lives under `metrics/<metric-slug>/` and is committed with it.

## Recipe 1 — Instrumented: warehouse / SQL

For numbers that already live in a database. Cheapest and most reliable.

```bash
: "${DATABASE_URL_READONLY:?}"
value=$(psql "$DATABASE_URL_READONLY" -At -f "$(dirname "$0")/query.sql")
echo "$value"
echo "source: query.sql @ $(date -u +%FT%TZ)" >&2
```

`query.sql` holds the definition so the metric is auditable and stable:

```sql
-- 7-day activation: signups who created a first project within 7 days
SELECT round(100.0 * count(*) FILTER (WHERE activated) / nullif(count(*), 0))
FROM (
  SELECT u.id,
         bool_or(p.created_at <= u.created_at + interval '7 days') AS activated
  FROM users u LEFT JOIN projects p ON p.user_id = u.id
  WHERE u.created_at >= now() - interval '30 days'
  GROUP BY u.id
) s;
```

## Recipe 2 — Instrumented: analytics / SaaS API

When the number lives in PostHog / Amplitude / GA / Stripe. Read via their API or a
pre-exported file the human drops in.

```bash
: "${POSTHOG_API_KEY:?}"
value=$(curl -sf -H "Authorization: Bearer $POSTHOG_API_KEY" \
  "https://app.posthog.com/api/projects/<id>/insights/<insight>/?refresh=true" \
  | jq -r '.result[0].aggregated_value')
echo "$value"; echo "source: posthog insight <insight>" >&2
```

## Recipe 3 — Elicited: LLM-as-judge over collected artifacts

For qualitative metrics — interviews, tickets, reviews. The instrument is a **fixed
rubric** applied by a judge to a **committed set of artifacts**, so a qualitative metric
becomes a reproducible number. This reuses `/intent`'s fuzzy-check machinery.

```bash
# transcripts/ holds the collected artifacts being scored this round.
dir="$(dirname "$0")"
verdict=$(claude -p --model claude-haiku-4-5 "$(cat <<EOF
Apply the rubric in rubric.md to each transcript in transcripts/.
Rubric: $(cat "$dir/rubric.md")
Transcripts:
$(for f in "$dir"/transcripts/*.txt; do echo "=== $f ==="; cat "$f"; done)

Output ONLY the metric value: the count of transcripts that satisfy the rubric, as
"N/<total>". Low temperature; judge only what's stated, don't infer.
EOF
)")
echo "$verdict"; echo "source: rubric.md over $(ls "$dir"/transcripts/*.txt | wc -l) transcripts" >&2
```

Pin the model and keep the rubric tight — this is the one recipe with real per-run cost.
The *set of artifacts* grows over time; the *rubric* stays fixed so readings are
comparable.

## Recipe 4 — Proxy: product-emitted event

When the true outcome is too slow to read in a cycle, read a fast event that stands in for
it (an "aha" event, a key action). Usually a thin variant of Recipe 1 or 2 against the
event stream — name in the metric block that it's a **proxy** so `/evaluate-outcome` reads
it as a leading signal, not the lagging truth.

## Choosing the shape

For the metric, pick the cheapest instrument that genuinely reads it:

- Number already in a DB/warehouse → **instrumented: SQL**.
- Number in an analytics/billing tool → **instrumented: API/export**.
- Outcome is experiential / in users' words → **elicited: judge over artifacts**.
- True outcome too slow for a cycle → **proxy** event, marked as such.

## Conventions
- The probe lives at `<vision-name>/metrics/<metric-slug>/measure-outcome.sh`.
- `chmod +x` it before committing.
- Everything the probe reads (`query.sql`, `rubric.md`, exports) lives in the same
  `<vision-name>/metrics/<metric-slug>/` dir and is committed with it.
- Runnable from the roadmap-home root: `./<vision-name>/metrics/<metric-slug>/measure-outcome.sh`.
- Always finish with the baseline loop (`references/baseline-right-reason.md`) before
  committing — a probe whose reading you haven't seen is not done.
