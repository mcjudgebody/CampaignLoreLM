#!/usr/bin/env bash
# lore-get.sh — UUID-driven lore retrieval from canon-manifest.json.
#
# Usage:
#   lore-get.sh --path    <UUID> [<manifest>]
#   lore-get.sh --body    <UUID> [<manifest>]
#   lore-get.sh --meta    <UUID> [<manifest>]
#   lore-get.sh --history <UUID> [--last <N>] [<manifest>]
#
# Modes:
#   --path    Print the file path for the given UUID.
#   --body    Print the document body (everything after the closing ___ of
#             the metadata block). No metadata overhead.
#   --meta    Print a compact metadata summary: title, version, status,
#             canonical_scope, last_updated. Reads from extended_index.
#   --history Print release history from extended_index.release_history.
#             Use --last N to show only the N most recent releases.
#             Requires history-mirror.sh to have been run.
#
# UUID lookup order: extended_index → canonical_documents (fallback).
# All modes work as long as extended_index has been populated by
# manifest-index.sh. For --history, history-mirror.sh must also have run.
#
# Exit codes:
#   0 — success
#   1 — usage error, UUID not found, or file missing

set -euo pipefail

# ── Arg parsing ────────────────────────────────────────────────────────────
MODE=""
UUID=""
LAST_N=0
MANIFEST_ARG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path|--body|--meta|--history)
      MODE="$1"; shift
      [[ $# -gt 0 ]] || { echo "ERROR: $MODE requires a UUID argument"; exit 1; }
      UUID="$1"; shift
      ;;
    --last)
      shift
      [[ $# -gt 0 ]] || { echo "ERROR: --last requires a number"; exit 1; }
      LAST_N="$1"; shift
      ;;
    *)
      MANIFEST_ARG="$1"; shift
      ;;
  esac
done

if [[ -z "$MODE" || -z "$UUID" ]]; then
  echo "Usage: $(basename "$0") --path|--body|--meta|--history <UUID> [--last N] [<manifest>]"
  exit 1
fi

MANIFEST="${MANIFEST_ARG:-canon-manifest.json}"

if [[ ! -f "$MANIFEST" ]]; then
  echo "ERROR: manifest not found: $MANIFEST"
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$MANIFEST")" && pwd)"
MANIFEST="$REPO_ROOT/$(basename "$MANIFEST")"

# ── UUID lookup ─────────────────────────────────────────────────────────────
# Try extended_index first, then canonical_documents as fallback.
RELPATH=""

if jq -e '.extended_index' "$MANIFEST" > /dev/null 2>&1; then
  RELPATH=$(jq -r --arg u "$UUID" \
    '.extended_index[] | select(.uuid == $u) | .file_path' \
    "$MANIFEST" 2>/dev/null || true)
fi

if [[ -z "$RELPATH" ]]; then
  RELPATH=$(jq -r --arg u "$UUID" \
    '.canonical_documents[] | select(.uuid == $u) | .file_path' \
    "$MANIFEST" 2>/dev/null || true)
fi

if [[ -z "$RELPATH" ]]; then
  echo "ERROR: UUID not found in manifest: $UUID"
  exit 1
fi

FULLPATH="$REPO_ROOT/$RELPATH"

if [[ ! -f "$FULLPATH" ]]; then
  echo "ERROR: file not found: $RELPATH"
  exit 1
fi

# ── Mode dispatch ───────────────────────────────────────────────────────────

case "$MODE" in

  --path)
    echo "$RELPATH"
    ;;

  --body)
    # Extract everything after the second ___ delimiter.
    second_delim=$(grep -En '^___$' "$FULLPATH" 2>/dev/null \
      | awk -F: 'NR==2{print $1}' || true)
    if [[ -z "$second_delim" ]]; then
      echo "ERROR: no closing ___ found in $RELPATH"
      exit 1
    fi
    tail -n +"$((second_delim + 1))" "$FULLPATH"
    ;;

  --meta)
    if ! jq -e '.extended_index' "$MANIFEST" > /dev/null 2>&1; then
      echo "ERROR: extended_index not found. Run manifest-index.sh first."
      exit 1
    fi
    jq -r --arg u "$UUID" '
      .extended_index[]
      | select(.uuid == $u)
      | "Title:          \(.title)\nVersion:         \(.version)\nStatus:          \(.status)\nScope:           \(.canonical_scope)\nLast Updated:    \(.last_updated)\nFile:            \(.file_path)\nUUID:            \(.uuid)"
    ' "$MANIFEST"
    ;;

  --history)
    if ! jq -e '.extended_index' "$MANIFEST" > /dev/null 2>&1; then
      echo "ERROR: extended_index not found. Run manifest-index.sh first."
      exit 1
    fi

    # Check release_history exists for this UUID
    has_rh=$(jq -r --arg u "$UUID" '
      .extended_index[]
      | select(.uuid == $u)
      | if has("release_history") then "yes" else "no" end
    ' "$MANIFEST" 2>/dev/null || echo "no")

    if [[ "$has_rh" != "yes" ]]; then
      echo "ERROR: release_history not populated for $UUID. Run history-mirror.sh first."
      exit 1
    fi

    jq -r --arg u "$UUID" --argjson n "$LAST_N" '
      .extended_index[]
      | select(.uuid == $u)
      | .release_history
      | if $n > 0 then .[0:$n] else . end
      | .[]
      | "## \(.to) (from \(.from))\n" + (
          .notes | map("  - " + .) | join("\n")
        )
    ' "$MANIFEST"
    ;;

esac
