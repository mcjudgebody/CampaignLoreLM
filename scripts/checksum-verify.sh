#!/usr/bin/env bash
# checksum-verify.sh — Verify (and optionally update) SHA-256 checksums
#                      in canon document metadata blocks.
#
# Usage:
#   checksum-verify.sh [--update] <file...>
#
# Computes the SHA-256 hash of each document's body (everything after the
# second ___ delimiter line) and compares it to the stored **Checksum:** field.
#
# A stored value that is not a valid 64-char lowercase hex string (e.g. a
# placeholder like <SHA-256-HEX>) is treated as a mismatch and can be
# written with --update just like a stale hash.
#
# Exit codes:
#   0 — all files OK (or no checkable metadata block found)
#   1 — one or more mismatches or invalid checksums found

set -euo pipefail

# ── Portability ────────────────────────────────────────────────────────────
# Use sha256sum (Linux/GNU) or shasum -a 256 (macOS/BSD).
sha256_stdin() {
  if command -v sha256sum &>/dev/null; then
    sha256sum | cut -d' ' -f1
  else
    shasum -a 256 | awk '{print $1}'
  fi
}

# BSD sed (macOS) requires -i '' for in-place edit; GNU sed (Linux) uses -i.
if sed --version &>/dev/null 2>&1; then
  sedi() { sed -i "$@"; }
else
  sedi() { sed -i '' "$@"; }
fi

UPDATE=false
if [[ "${1:-}" == "--update" ]]; then
  UPDATE=true
  shift
fi

if [[ $# -eq 0 ]]; then
  echo "Usage: $(basename "$0") [--update] <file...>"
  exit 1
fi

EXIT=0

for f in "$@"; do
  # Locate the two ___ block delimiters.
  # Per spec, documents with a metadata block MUST begin with ___ on line 1.
  first_delim=$(grep -m1 -En '^___$' "$f" 2>/dev/null | cut -d: -f1)
  second_delim=$(grep -En '^___$' "$f" 2>/dev/null | awk -F: 'NR==2{print $1}')

  if [[ -z "$first_delim" || -z "$second_delim" || "$first_delim" != "1" ]]; then
    echo "SKIP: $f (no metadata block)"
    continue
  fi

  # Compute the actual SHA-256 of the document body (lines after second ___).
  actual=$(tail -n +"$((second_delim + 1))" "$f" | sha256_stdin)

  # Check whether a **Checksum:** field exists in the metadata block at all.
  # A missing field is a structural problem we cannot fix automatically.
  checksum_line=$(awk -v s="$first_delim" -v e="$second_delim" \
    'NR>s && NR<e && /^\*\*Checksum:\*\*/{print; exit}' "$f")

  if [[ -z "$checksum_line" ]]; then
    echo "SKIP: $f (Checksum field absent — fix metadata structure manually)"
    continue
  fi

  # Extract the stored value. Valid only if exactly 64 lowercase hex chars.
  stored=$(echo "$checksum_line" | sed -E 's/.*`([0-9a-f]{64})`.*/\1/')

  if [[ ${#stored} -eq 64 && "$stored" == "$actual" ]]; then
    echo "OK:   $f"
  else
    if [[ ${#stored} -ne 64 ]]; then
      echo "FAIL: $f (stored checksum is not a valid SHA-256 hex string)"
    else
      echo "FAIL: $f"
      echo "      stored: $stored"
      echo "      actual: $actual"
    fi
    EXIT=1
    if $UPDATE; then
      # Replace whatever is between the Checksum backticks with the correct
      # hash, preserving two trailing spaces. Handles placeholders and stale
      # hashes equally — matches any value between the backticks.
      sedi -E \
        "s/^(\*\*Checksum:\*\* \`)[^\`]*(\`)[[:space:]]*\$/\1${actual}\2  /" \
        "$f"
      echo " UPD: $f"
    fi
  fi
done

exit $EXIT
