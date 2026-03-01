#!/usr/bin/env bash
# metadata-lint.sh — Check (and optionally fix) trailing-space compliance
#                    on metadata field lines in canon documents.
#
# Usage:
#   metadata-lint.sh [--fix] <file...>
#
# Checks that every field line in the primary metadata block (above
# "## Versioning Notes") ends with exactly two trailing space characters,
# as required by the AGENTS.md spec for correct Markdown line-break rendering.
#
# Exit codes:
#   0 — all files OK (or all violations fixed)
#   1 — one or more violations found

set -euo pipefail

# ── Portability ────────────────────────────────────────────────────────────
# BSD sed (macOS) requires -i '' for in-place edit; GNU sed (Linux) uses -i.
if sed --version &>/dev/null 2>&1; then
  sedi() { sed -i "$@"; }
else
  sedi() { sed -i '' "$@"; }
fi

FIX=false
if [[ "${1:-}" == "--fix" ]]; then
  FIX=true
  shift
fi

if [[ $# -eq 0 ]]; then
  echo "Usage: $(basename "$0") [--fix] <file...>"
  exit 1
fi

EXIT=0

for f in "$@"; do
  # Locate the two ___ block delimiters that bound the metadata block.
  # Per spec, documents with a metadata block MUST begin with ___ on line 1.
  # This excludes files where ___ appears only in body text or code blocks.
  first_delim=$(grep -m1 -En '^___$' "$f" 2>/dev/null | cut -d: -f1)
  second_delim=$(grep -En '^___$' "$f" 2>/dev/null | awk -F: 'NR==2{print $1}')

  if [[ -z "$first_delim" || -z "$second_delim" || "$first_delim" != "1" ]]; then
    echo "SKIP: $f (no metadata block)"
    continue
  fi

  # Find ## Versioning Notes only within the metadata block (between the two ___).
  vline=$(awk -v s="$first_delim" -v e="$second_delim" \
    'NR>s && NR<e && /^## Versioning Notes$/ {print NR; exit}' "$f")

  if [[ -z "$vline" ]]; then
    echo "SKIP: $f (metadata block present but malformed)"
    continue
  fi

  # Count field lines above ## Versioning Notes that do NOT end with two spaces.
  # Filter out blank lines, the ___ delimiter, and the # Document Metadata header.
  bad=$(head -n "$((vline - 1))" "$f" \
        | grep -vE '^[[:space:]]*$|^___$|^# Document Metadata$' \
        | grep -cvE '  $' \
        || true)

  if [[ "$bad" -gt 0 ]]; then
    echo "FAIL [$bad line(s)]: $f"
    EXIT=1
    if $FIX; then
      # Strip any trailing whitespace from matching field lines and add exactly two spaces.
      # Scoped to lines 1 through (vline - 1) to avoid touching the document body.
      sedi -E "1,$((vline - 1)) s/^(\*\*[^:]+:.*[^[:space:]])[[:space:]]*$/\1  /" "$f"
      echo " FIX: $f"
    fi
  else
    echo "OK:   $f"
  fi
done

exit $EXIT
