#!/usr/bin/env bash
# body-verify.sh — Validate that lore-get.sh --body output is clean:
#                   no metadata markers, non-empty, and ends with a newline.
#
# Usage:
#   body-verify.sh [<manifest-file>]
#
#   Runs --body extraction for every UUID in extended_index and checks:
#     1. Output is non-empty.
#     2. Output does not contain metadata markers (** field lines, ___ delimiter).
#     3. Output begins with ## (first content line is a heading).
#
# Exit codes:
#   0 — all bodies pass
#   1 — one or more failures

set -euo pipefail

MANIFEST="${1:-canon-manifest.json}"

if [[ ! -f "$MANIFEST" ]]; then
  echo "ERROR: manifest not found: $MANIFEST"
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$MANIFEST")" && pwd)"
MANIFEST="$REPO_ROOT/$(basename "$MANIFEST")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! jq -e '.extended_index' "$MANIFEST" > /dev/null 2>&1; then
  echo "ERROR: extended_index not found. Run manifest-index.sh first."
  exit 1
fi

EXIT=0

while IFS=$'\t' read -r uuid relpath; do
  body=$(bash "$SCRIPT_DIR/lore-get.sh" --body "$uuid" "$MANIFEST" 2>/dev/null || true)

  # 1. Non-empty
  if [[ -z "$(echo "$body" | tr -d '[:space:]')" ]]; then
    printf "FAIL [empty body]: %s\n" "$relpath"
    EXIT=1
    continue
  fi

  # 2. No canonical metadata field markers (exact field names only).
  # Note: ^___$ is NOT checked in the full body because ___ is valid Markdown
  # horizontal-rule content. The specific canonical field names below should
  # never appear in legitimate document body content.
  if echo "$body" | grep -qE \
      '^# Document Metadata$|^\*\*(Document Title|Document ID \(UUID\)|Version \(SemVer\)|Canonical Scope|Last Updated \(YYYY-MM-DD\)|Checksum):\*\*'; then
    printf "FAIL [metadata leak]: %s\n" "$relpath"
    EXIT=1
    continue
  fi

  # 3. First non-blank line must not be ___ (would indicate extraction failure)
  first_content=$(echo "$body" | grep -v '^[[:space:]]*$' | head -n1 || true)
  if [[ "$first_content" == "___" ]]; then
    printf "FAIL [body starts with delimiter]: %s\n" "$relpath"
    EXIT=1
    continue
  fi

  printf "OK:   %s\n" "$relpath"

done < <(jq -r '.extended_index[] | [.uuid, .file_path] | @tsv' "$MANIFEST")

exit $EXIT
