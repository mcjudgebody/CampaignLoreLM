#!/usr/bin/env bash
# canon-validate.sh — Validates canonical documents against canon-manifest.json.
#
# Usage:
#   canon-validate.sh [--update] [<manifest-file>]
#
#   Default <manifest-file>: canon-manifest.json (relative to CWD, expected = repo root)
#
# Validate mode (default):
#   1. Verifies CANON.md self-integrity via checksum-verify.sh.
#   2. For each manifest entry, reads the actual file and compares
#      UUID, Version, and Checksum.
#   3. If manifest passes, scans CANON.md inline authority pointer lines for
#      each UUID and verifies their versions match the manifest.
#   4. Checks extended_index version freshness for all canonical_documents.
#
# Update mode (--update):
#   1. Verifies CANON.md self-integrity first (refuses a dirty source).
#   2. For each manifest entry, reads actual file metadata and updates the
#      manifest JSON (version + checksum).
#   3. Updates CANON.md §6.2 Version column and inline pointer versions.
#   4. Re-finalizes CANON.md (metadata-lint --fix, checksum --update, verify).
#   5. Refreshes extended_index via manifest-index.sh and release_history via
#      history-mirror.sh, keeping the retrieval layer current automatically.
#
# NOTE: Version and Last-Updated fields in CANON.md's own metadata block are
#       NOT modified by --update.  Those remain a conscious human/LLM action.
#
# Exit codes:
#   0 — all entries OK (validate) or update applied cleanly (update)
#   1 — one or more failures, or dirty CANON.md pre-check

set -euo pipefail

# ── Portability ────────────────────────────────────────────────────────────
# BSD sed (macOS) requires -i '' for in-place edit; GNU sed (Linux) uses -i.
if sed --version &>/dev/null 2>&1; then
  sedi() { sed -i "$@"; }
else
  sedi() { sed -i '' "$@"; }
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

UPDATE=false
if [[ "${1:-}" == "--update" ]]; then
  UPDATE=true
  shift
fi

MANIFEST="${1:-canon-manifest.json}"

if [[ ! -f "$MANIFEST" ]]; then
  echo "ERROR: manifest not found: $MANIFEST"
  exit 1
fi

# Repo root = directory containing the manifest (canon-manifest.json lives at root).
REPO_ROOT="$(cd "$(dirname "$MANIFEST")" && pwd)"
MANIFEST="$REPO_ROOT/$(basename "$MANIFEST")"
CANON="$REPO_ROOT/CANON.md"

EXIT=0

# ── Step 1: CANON.md self-integrity pre-check ──────────────────────────────
if ! bash "$SCRIPT_DIR/checksum-verify.sh" "$CANON" > /dev/null 2>&1; then
  echo "FAIL: CANON.md self-integrity check failed"
  echo "      Run: bash scripts/checksum-verify.sh CANON.md"
  exit 1
fi

# ── Helper: extract first backtick-enclosed value from metadata field ──────
# Usage: meta_field <file> <label-prefix>
# Example: meta_field foo.md "Document ID (UUID)"
meta_field() {
  local file="$1" label="$2"
  grep -m1 "^\*\*${label}:" "$file" 2>/dev/null \
    | sed 's/.*`\([^`]*\)`.*/\1/' \
    || echo ""
}

# ── Step 2: Process manifest entries ───────────────────────────────────────
TABLE_FAIL=0

while IFS=$'\t' read -r uuid filepath version checksum; do
  fullpath="$REPO_ROOT/$filepath"

  if [[ ! -f "$fullpath" ]]; then
    printf "MISSING: %s\n         UUID: %s\n" "$filepath" "$uuid"
    EXIT=1; TABLE_FAIL=1
    continue
  fi

  actual_uuid=$(    meta_field "$fullpath" "Document ID (UUID)")
  actual_version=$( meta_field "$fullpath" "Version (SemVer)")
  actual_checksum=$(meta_field "$fullpath" "Checksum")

  if $UPDATE; then
    # ── Update manifest entry ────────────────────────────────────────────────
    tmp=$(mktemp)
    jq --arg u  "$actual_uuid" \
       --arg v  "$actual_version" \
       --arg c  "$actual_checksum" \
      '.canonical_documents |= map(if .uuid == $u then .version = $v | .checksum = $c else . end)' \
      "$MANIFEST" > "$tmp" && mv "$tmp" "$MANIFEST"

    # ── Update CANON.md §6.2 Version column for this UUID ───────────────────
    # Row format: | <pillar> | `<filepath>` | `<uuid>` | `<version>` |
    # Pattern: match uuid backtick value, then pipe+space, then old version.
    sedi -E \
      "s/(\`${uuid}\`[[:space:]]*\|[[:space:]]*)\`[0-9]+\.[0-9]+\.[0-9]+\`/\1\`${actual_version}\`/" \
      "$CANON"

    # ── Update CANON.md inline pointer version for this UUID ────────────────
    # Pointer format: (`<uuid>` v<version>)
    sedi -E \
      "s/(\`${uuid}\` v)[0-9]+\.[0-9]+\.[0-9]+/\1${actual_version}/" \
      "$CANON"

    printf " UPD: %-46s v%s  %s...\n" \
      "$filepath" "$actual_version" "${actual_checksum:0:8}"

  else
    # ── Validate file against manifest entry ────────────────────────────────
    row_ok=1

    if [[ "$uuid" != "$actual_uuid" ]]; then
      printf "FAIL: %s\n      field:    UUID\n      manifest: %s\n      file:     %s\n" \
        "$filepath" "$uuid" "$actual_uuid"
      row_ok=0; EXIT=1; TABLE_FAIL=1
    fi

    if [[ "$version" != "$actual_version" ]]; then
      printf "FAIL: %s\n      field:    Version\n      manifest: %s\n      file:     %s\n" \
        "$filepath" "$version" "$actual_version"
      row_ok=0; EXIT=1; TABLE_FAIL=1
    fi

    if [[ "$checksum" != "$actual_checksum" ]]; then
      printf "FAIL: %s\n      field:    Checksum\n      manifest: %s\n      file:     %s\n" \
        "$filepath" "$checksum" "$actual_checksum"
      row_ok=0; EXIT=1; TABLE_FAIL=1
    fi

    [[ "$row_ok" -eq 1 ]] && printf "OK:   %s\n" "$filepath"
  fi

done < <(jq -r '.canonical_documents[] | [.uuid, .file_path, .version, .checksum] | @tsv' "$MANIFEST")

# ── Step 3: Post-update finalization ────────────────────────────────────────
if $UPDATE; then
  printf "\nFinalizing CANON.md...\n"
  bash "$SCRIPT_DIR/metadata-lint.sh"   --fix    "$CANON" > /dev/null 2>&1 || true
  bash "$SCRIPT_DIR/checksum-verify.sh" --update "$CANON" > /dev/null 2>&1 || true
  bash "$SCRIPT_DIR/metadata-lint.sh"            "$CANON"
  bash "$SCRIPT_DIR/checksum-verify.sh"          "$CANON"

  # ── Step 4: Refresh extended_index and release_history ──────────────────
  printf "\nRefreshing extended_index...\n"
  bash "$SCRIPT_DIR/manifest-index.sh" "$MANIFEST" || true
  bash "$SCRIPT_DIR/history-mirror.sh" "$MANIFEST" > /dev/null 2>&1 || true
  exit 0
fi

# ── Step 4: CANON.md inline pointer version check (only if manifest passed) ─
if [[ "$TABLE_FAIL" -eq 0 ]]; then
  printf "\n--- CANON.md inline pointer check ---\n"
  inline_fail=0

  while IFS=$'\t' read -r uuid filepath version checksum; do
    # Find all inline pointer lines in CANON.md: start with "* " and contain `<uuid>`.
    mapfile -t hits < <(
      grep -En "^\* .+\(\`${uuid}\`" "$CANON" 2>/dev/null || true
    )

    if [[ "${#hits[@]}" -eq 0 ]]; then
      printf "WARN: %-46s no inline pointer found\n" "$filepath"
      continue
    fi

    escaped_version="${version//./\\.}"
    for hit in "${hits[@]}"; do
      lineno="${hit%%:*}"
      line="${hit#*:}"
      if echo "$line" | grep -qE "\`${uuid}\` v${escaped_version}"; then
        printf "OK:   inline %-43s (line %s)\n" "$filepath" "$lineno"
      else
        printf "FAIL: inline %s (line %s) — version mismatch\n      expected: v%s\n" \
          "$filepath" "$lineno" "$version"
        inline_fail=1; EXIT=1
      fi
    done

  done < <(jq -r '.canonical_documents[] | [.uuid, .file_path, .version, .checksum] | @tsv' "$MANIFEST")

  [[ "$inline_fail" -eq 0 ]] && printf "\nAll inline pointers match manifest.\n"
fi

# ── Step 5: extended_index staleness check (canonical_documents only) ───────
if [[ "$TABLE_FAIL" -eq 0 ]]; then
  printf "\n--- extended_index freshness check ---\n"
  index_warn=0

  while IFS=$'\t' read -r uuid filepath version checksum; do
    fullpath="$REPO_ROOT/$filepath"
    [[ ! -f "$fullpath" ]] && continue

    idx_version=$(jq -r --arg u "$uuid" \
      '[.extended_index[] | select(.uuid == $u) | .version] | first // ""' \
      "$MANIFEST" 2>/dev/null || echo "")

    if [[ -z "$idx_version" ]]; then
      printf "WARN: %-46s not in extended_index\n" "$filepath"
      index_warn=1
    elif [[ "$idx_version" != "$version" ]]; then
      printf "WARN: %-46s stale (index: v%s, live: v%s)\n" \
        "$filepath" "$idx_version" "$version"
      index_warn=1
    fi
  done < <(jq -r '.canonical_documents[] | [.uuid, .file_path, .version, .checksum] | @tsv' "$MANIFEST")

  if [[ "$index_warn" -eq 0 ]]; then
    printf "OK:   extended_index is current for all canonical documents.\n"
  else
    printf "\nRun: bash scripts/canon-validate.sh --update  to refresh extended_index\n"
  fi
fi

exit $EXIT
