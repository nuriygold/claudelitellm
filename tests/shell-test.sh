#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash -n "$ROOT/bin/claudelitellm" "$ROOT/bin/bootstrap-claude-config" "$ROOT/bin/trim-agent-descriptions"
grep -q 'FILTER_MAX_TOOLS="\${FILTER_MAX_TOOLS:-128}"' "$ROOT/bin/claudelitellm"
grep -q 'DROP_KEYS = {"output_config"}' "$ROOT/bin/claudelitellm"
grep -q 'FILTER_BIND_HOST' "$ROOT/bin/claudelitellm"
! grep -R -nE '/Users/[A-Za-z0-9._-]+|sk-[A-Za-z0-9]|ghp_[A-Za-z0-9]' \
  "$ROOT/.claude" "$ROOT/config" "$ROOT/devices" "$ROOT/README.md" "$ROOT/CLAUDE.md"
grep -q 'REPLACE_WITH_YOUR' "$ROOT/.claude/claudelitellmmcps.example.json"

echo "claudelitellm shell and public-safety checks passed"
