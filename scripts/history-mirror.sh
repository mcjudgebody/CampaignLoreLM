#!/usr/bin/env bash
# history-mirror.sh — Parse inline Release Notes from each document's metadata
#                      block and add release_history arrays to extended_index
#                      entries in canon-manifest.json.
#
# Usage:
#   history-mirror.sh [<manifest-file>]
#
#   Requires manifest-index.sh to have been run first (extended_index must exist).
#
# Release Notes format expected inside the metadata block:
#   ## Release Notes (from <prev> → <next>)
#   - <note 1>
#   - <note 2>
#
# Output per extended_index entry:
#   "release_history": [
#     { "from": "<prev>", "to": "<next>", "notes": ["<note1>", "<note2>"] },
#     ...
#   ]
#
# Entries are ordered as they appear in the document (most-recent-first by convention).
# Idempotent: replaces release_history on each run.
#
# Exit codes:
#   0 — success
#   1 — manifest not found, jq unavailable, or extended_index absent

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

if ! jq -e '.extended_index' "$MANIFEST" > /dev/null 2>&1; then
  echo "ERROR: extended_index not found in manifest. Run manifest-index.sh first."
  exit 1
fi

# ── Parse release notes from a single file's metadata block ────────────────
# Outputs a JSON array of { from, to, notes[] } objects.
parse_release_notes() {
  local file="$1"
  local first_delim second_delim

  first_delim=$(grep -m1 -En '^___$' "$file" 2>/dev/null | cut -d: -f1 || true)
  second_delim=$(grep -En '^___$' "$file" 2>/dev/null | awk -F: 'NR==2{print $1}' || true)

  if [[ -z "$first_delim" || -z "$second_delim" || "$first_delim" != "1" ]]; then
    echo "[]"
    return
  fi

  # Use awk to extract release note blocks from within the metadata block.
  # The arrow (→, U+2192) is space-separated, so splitting on " " isolates it cleanly.
  awk -v s="$first_delim" -v e="$second_delim" '
    BEGIN {
      in_block  = 0
      from_ver  = ""
      to_ver    = ""
      note_count = 0
      block_count = 0
    }

    NR <= s || NR >= e { next }

    /^## Release Notes \(from / {
      # Flush previous block if open
      if (in_block && (from_ver != "" || to_ver != "")) {
        flush_block()
      }
      # Extract "from" and "to" versions
      line = $0
      sub(/^## Release Notes \(from /, "", line)
      sub(/\).*$/, "", line)
      # line is now e.g. "1.0.0 → 1.1.0" or "— → 1.0.0"
      n = split(line, parts, " ")
      from_ver   = parts[1]
      to_ver     = (n >= 3 ? parts[3] : (n == 1 ? parts[1] : parts[2]))
      in_block   = 1
      note_count = 0
      next
    }

    in_block && /^- / {
      note = substr($0, 3)
      gsub(/[[:space:]]+$/, "", note)
      notes[note_count++] = note
      next
    }

    in_block && /^## / {
      flush_block()
      in_block = 0
      from_ver = ""; to_ver = ""
      next
    }

    function flush_block(    i, out) {
      out = sprintf("{\"from\":\"%s\",\"to\":\"%s\",\"notes\":[", from_ver, to_ver)
      for (i = 0; i < note_count; i++) {
        n = notes[i]
        gsub(/"/, "\\\"", n)
        out = out (i > 0 ? "," : "") "\"" n "\""
      }
      out = out "]}"
      print out
      block_count++
      note_count = 0
      delete notes
    }

    END {
      if (in_block && (from_ver != "" || to_ver != "")) {
        flush_block()
      }
    }
  ' "$file" | jq -s '.'
}

# ── Process each extended_index entry ──────────────────────────────────────
while IFS=$'\t' read -r uuid relpath; do
  fullpath="$REPO_ROOT/$relpath"

  if [[ ! -f "$fullpath" ]]; then
    printf "SKIP: %s (file not found)\n" "$relpath"
    continue
  fi

  release_json=$(parse_release_notes "$fullpath")
  count=$(echo "$release_json" | jq 'length')

  tmp=$(mktemp)
  jq --arg uuid "$uuid" \
     --argjson rh "$release_json" \
     '.extended_index |= map(if .uuid == $uuid then . + {release_history: $rh} else . end)' \
     "$MANIFEST" > "$tmp" && mv "$tmp" "$MANIFEST"

  printf "  RH:  %-48s (%d release(s))\n" "$relpath" "$count"

done < <(jq -r '.extended_index[] | [.uuid, .file_path] | @tsv' "$MANIFEST")

echo ""
echo "release_history: mirrored for all extended_index entries."
