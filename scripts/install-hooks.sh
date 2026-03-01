#!/usr/bin/env bash
# install-hooks.sh — One-time setup to activate the pre-commit hook.
# Run once per clone: bash scripts/install-hooks.sh

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

git config core.hooksPath scripts/hooks
chmod +x scripts/hooks/pre-commit

echo "OK: pre-commit hook installed (core.hooksPath = scripts/hooks)"
echo "    git commit will now automatically validate staged Markdown files."
echo "    To bypass: git commit --no-verify"
