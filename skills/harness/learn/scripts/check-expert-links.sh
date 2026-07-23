#!/usr/bin/env bash
# check-expert-links.sh — mechanical link gate for the project's lazy memory.
#
# Reference files under .claude/skills/expert/references/ cross-link via Obsidian
# wikilinks ([[basename]] resolving to basename.md in the same directory). Renames,
# deletions, and typos break these silently — this lint makes those failures loud.
# Wire it into scripts/local-checks.sh (and CI) so a broken Expert link fails the
# build.
#
# Checks:
#   1. Every [[<slug>]] token in every references/*.md resolves to <slug>.md in
#      the same directory.
#   2. Slugs match the convention [a-z0-9-]+ (lowercase, hyphenated).
#
# Warns (does NOT fail):
#   - Orphan files (no inbound wikilink from any other reference) — top-level
#     concepts can legitimately be orphans.
#
# Exit 0 = clean. Exit 1 = at least one broken or malformed link.
#
# The Expert root is tweakable via env; default is .claude/skills/expert.

set -euo pipefail

EXPERT_ROOT="${EXPERT_ROOT:-.claude/skills/expert}"
REF_DIR="${EXPERT_ROOT}/references"

fail=0
note() { echo "❌ $*" >&2; fail=1; }
warn() { echo "⚠️  $*" >&2; }

if [[ ! -d "$REF_DIR" ]]; then
  echo "no Expert at ${REF_DIR} (nothing to check)"
  exit 0
fi

mapfile -t files < <(find "$REF_DIR" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort)

if (( ${#files[@]} == 0 )); then
  echo "no reference files in ${REF_DIR} (nothing to check)"
  exit 0
fi

# Build the set of valid slugs (filenames without .md) for fast existence check.
declare -A valid_slug
for f in "${files[@]}"; do
  base="$(basename "$f" .md)"
  valid_slug["$base"]=1
done

# Track inbound link counts to surface orphan warnings.
declare -A inbound_count
for f in "${files[@]}"; do
  base="$(basename "$f" .md)"
  inbound_count["$base"]=0
done

slug_re='^[a-z0-9-]+$'

for f in "${files[@]}"; do
  # Extract every [[...]] token.
  while IFS= read -r token; do
    [[ -z "$token" ]] && continue
    # Strip leading [[ and trailing ]] (escape the brackets so bash treats them
    # as literals, not as bracket-expression delimiters in the pattern).
    slug="${token##\[\[}"
    slug="${slug%%\]\]}"

    # Convention check: lowercase, alphanumeric + hyphen, no path, no extension,
    # no alias.
    if ! [[ "$slug" =~ $slug_re ]]; then
      note "$f: malformed wikilink '[[${slug}]]' — slugs must match [a-z0-9-]+ (no paths, no extensions, no aliases). See wikilink-convention.md."
      continue
    fi

    # Existence check: target file must exist in references/.
    if [[ -z "${valid_slug[$slug]:-}" ]]; then
      note "$f: wikilink '[[${slug}]]' does not resolve — no file ${REF_DIR}/${slug}.md. Fix the link or restore the file."
      continue
    fi

    # Don't count self-links as inbound.
    src_base="$(basename "$f" .md)"
    if [[ "$slug" != "$src_base" ]]; then
      inbound_count["$slug"]=$((inbound_count["$slug"] + 1))
    fi
  done < <(grep -oE '\[\[[^]]+\]\]' "$f" || true)
done

# Orphan warnings (informational only — SKILL.md / top-level concepts are
# expected to be orphans).
for slug in "${!inbound_count[@]}"; do
  if (( inbound_count[$slug] == 0 )); then
    warn "${REF_DIR}/${slug}.md has no inbound wikilinks (orphan — informational only)."
  fi
done

if (( fail )); then
  echo "check-expert-links: FAIL" >&2
  exit 1
fi
echo "check-expert-links: OK (${#files[@]} file(s))"
