#!/usr/bin/env bash
# manifest-index.sh — Scan all metadata-bearing .md files in the repo and
#                      populate (or refresh) the extended_index key in
#                      canon-manifest.json.
#
# Usage:
#   manifest-index.sh [<manifest-file>]
#
#   Default <manifest-file>: canon-manifest.json (relative to CWD)
#
# Behavior:
#   Scans every .md file under REPO_ROOT for a valid metadata block
#   (file must begin with ___ on line 1). For each qualifying file, extracts:
#     uuid, file_path, title, version, status, canonical_scope,
#     last_updated, checksum
#   Writes all entries to the extended_index array in the manifest JSON,
#   replacing any previous extended_index content entirely (idempotent).
#   Does NOT touch canonical_documents.
#
# Exit codes:
#   0 — success
#   1 — manifest not found or jq unavailable

set -euo pipefail

MANIFEST="${1:-canon-manifest.json}"

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

# ── Helper: extract a metadata field value ─────────────────────────────────
# Handles both backtick-wrapped and bare-text field values.
# Strips trailing whitespace (the required two trailing spaces on field lines).
meta_field() {
  local file="$1" label="$2"
  local line
  line=$(grep -m1 "^\*\*${label}:" "$file" 2>/dev/null || true)
  [[ -z "$line" ]] && echo "" && return
  # Try backtick-wrapped value first
  local val
  val=$(echo "$line" | sed -n 's/.*`\([^`]*\)`.*/\1/p')
  if [[ -z "$val" ]]; then
    # Bare text: strip label prefix and trailing whitespace
    val=$(echo "$line" | sed 's/^\*\*[^:]*:\*\*[[:space:]]*//' | sed 's/[[:space:]]*$//')
  fi
  echo "$val"
}

INDEX_ENTRIES=()

while IFS= read -r filepath; do
  relpath="${filepath#$REPO_ROOT/}"

  # Skip if file doesn't start with ___ on line 1
  first_line=$(head -n1 "$filepath" 2>/dev/null || true)
  [[ "$first_line" != "___" ]] && continue

  uuid=$(meta_field "$filepath" "Document ID (UUID)")
  [[ -z "$uuid" ]] && continue

  title=$(        meta_field "$filepath" "Document Title")
  version=$(      meta_field "$filepath" "Version (SemVer)")
  status=$(       meta_field "$filepath" "Status")
  scope=$(        meta_field "$filepath" "Canonical Scope")
  last_updated=$( meta_field "$filepath" "Last Updated (YYYY-MM-DD)")
  checksum=$(     meta_field "$filepath" "Checksum")

  entry=$(jq -n \
    --arg uuid          "$uuid"    \
    --arg file_path     "$relpath" \
    --arg title         "$title"   \
    --arg version       "$version" \
    --arg status        "$status"  \
    --arg canonical_scope "$scope" \
    --arg last_updated  "$last_updated" \
    --arg checksum      "$checksum" \
    '{
      uuid:            $uuid,
      file_path:       $file_path,
      title:           $title,
      version:         $version,
      status:          $status,
      canonical_scope: $canonical_scope,
      last_updated:    $last_updated,
      checksum:        $checksum
    }')

  INDEX_ENTRIES+=("$entry")
  printf "  IDX: %s\n" "$relpath"
done < <(find "$REPO_ROOT" -name "*.md" | sort)

# Build array from collected entries and merge into manifest (idempotent replace)
array_json=$(printf '%s\n' "${INDEX_ENTRIES[@]}" | jq -s '.')

tmp=$(mktemp)
jq --argjson idx "$array_json" '. + {extended_index: $idx}' "$MANIFEST" > "$tmp" \
  && mv "$tmp" "$MANIFEST"

echo ""
echo "extended_index: ${#INDEX_ENTRIES[@]} entries written to $(basename "$MANIFEST")."
