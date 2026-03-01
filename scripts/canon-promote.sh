#!/usr/bin/env bash
# canon-promote.sh — Promote a document from extended_index to canonical_documents.
#
# Usage:
#   canon-promote.sh <UUID> [--pillar <description>] [<manifest-file>]
#
# Validates that:
#   1. UUID exists in extended_index.
#   2. Document Status is "Canon".
#   3. UUID is not already in canonical_documents.
#
# If all checks pass, appends a new entry to canonical_documents:
#   { "pillar": <description|null>, "file_path": ..., "uuid": ...,
#     "version": ..., "checksum": ... }
#
# After promotion, run:
#   bash scripts/canon-validate.sh          # confirm integrity
#   bash scripts/manifest-index.sh          # refresh extended_index (optional)
#   bash scripts/history-mirror.sh          # refresh release_history (optional)
#
# Exit codes:
#   0 — promoted successfully
#   1 — validation failure or usage error

set -euo pipefail

# ── Arg parsing ─────────────────────────────────────────────────────────────
UUID=""
PILLAR_SET=0
PILLAR=""
MANIFEST_ARG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pillar)
      shift
      [[ $# -gt 0 ]] || { echo "ERROR: --pillar requires a description argument"; exit 1; }
      PILLAR="$1"; PILLAR_SET=1; shift
      ;;
    -*)
      echo "ERROR: unknown option: $1"
      exit 1
      ;;
    *)
      if [[ -z "$UUID" ]]; then
        UUID="$1"; shift
      else
        MANIFEST_ARG="$1"; shift
      fi
      ;;
  esac
done

if [[ -z "$UUID" ]]; then
  echo "Usage: $(basename "$0") <UUID> [--pillar <description>] [<manifest-file>]"
  exit 1
fi

MANIFEST="${MANIFEST_ARG:-canon-manifest.json}"

if [[ ! -f "$MANIFEST" ]]; then
  echo "ERROR: manifest not found: $MANIFEST"
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is required"
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$MANIFEST")" && pwd)"
MANIFEST="$REPO_ROOT/$(basename "$MANIFEST")"

# ── Check 1: UUID exists in extended_index ───────────────────────────────────
if ! jq -e '.extended_index' "$MANIFEST" > /dev/null 2>&1; then
  echo "ERROR: extended_index not found. Run manifest-index.sh first."
  exit 1
fi

entry=$(jq --arg u "$UUID" '.extended_index[] | select(.uuid == $u)' "$MANIFEST" 2>/dev/null || true)

if [[ -z "$entry" ]]; then
  echo "ERROR: UUID not found in extended_index: $UUID"
  echo "       Run manifest-index.sh first, or check the UUID."
  exit 1
fi

title=$(    echo "$entry" | jq -r '.title')
file_path=$(echo "$entry" | jq -r '.file_path')
version=$(  echo "$entry" | jq -r '.version')
checksum=$( echo "$entry" | jq -r '.checksum')
status=$(   echo "$entry" | jq -r '.status')

# ── Check 2: Status must be "Canon" ─────────────────────────────────────────
if [[ "$status" != "Canon" ]]; then
  echo "ERROR: document Status is \"$status\" — only Status: Canon documents may be promoted."
  echo "       Update the document Status to Canon first, then re-index and retry."
  exit 1
fi

# ── Check 3: UUID must not already be in canonical_documents ─────────────────
already=$(jq -r --arg u "$UUID" '.canonical_documents[] | select(.uuid == $u) | .uuid' "$MANIFEST" 2>/dev/null || true)
if [[ -n "$already" ]]; then
  echo "ERROR: UUID is already in canonical_documents: $UUID"
  echo "       ($file_path)"
  exit 1
fi

# ── Build new entry ──────────────────────────────────────────────────────────
if [[ "$PILLAR_SET" -eq 1 ]]; then
  pillar_json=$(jq -n --arg p "$PILLAR" '$p')
else
  pillar_json="null"
fi

new_entry=$(jq -n \
  --argjson pillar   "$pillar_json" \
  --arg     fp       "$file_path"   \
  --arg     uuid     "$UUID"        \
  --arg     version  "$version"     \
  --arg     checksum "$checksum"    \
  '{
    pillar:    $pillar,
    file_path: $fp,
    uuid:      $uuid,
    version:   $version,
    checksum:  $checksum
  }')

# ── Append to canonical_documents ───────────────────────────────────────────
tmp=$(mktemp)
jq --argjson entry "$new_entry" \
  '.canonical_documents += [$entry]' \
  "$MANIFEST" > "$tmp" && mv "$tmp" "$MANIFEST"

# ── Report ───────────────────────────────────────────────────────────────────
echo "PROMOTED: $file_path"
echo "  UUID:     $UUID"
echo "  Title:    $title"
echo "  Version:  $version"
echo "  Pillar:   ${PILLAR:-<null>}"
echo ""
echo "Next steps:"
echo "  bash scripts/canon-validate.sh          # verify integrity"
echo "  bash scripts/canon-validate.sh --update # sync manifest + CANON.md pointers"
