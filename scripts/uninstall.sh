#!/usr/bin/env bash
# crystools — remove status line from ~/.claude/settings.json

set -euo pipefail

SETTINGS="$HOME/.claude/settings.json"

# Require jq
if ! command -v jq &>/dev/null; then
  echo "jq not found — install it: https://jqlang.github.io/jq/download/"
  exit 1
fi

if [ ! -f "$SETTINGS" ]; then
  echo "Nothing to uninstall — $SETTINGS not found."
  exit 0
fi

# Check if statusLine is configured
if ! jq -e '.statusLine' "$SETTINGS" &>/dev/null; then
  echo "Status line is not installed."
  exit 0
fi

# Remove statusLine + env.CRYSTOOLS_SL_ICONS (preserve everything else)
jq 'del(.statusLine) | if .env then .env |= del(.CRYSTOOLS_SL_ICONS) | if .env == {} then del(.env) else . end else . end' \
  "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"

echo ""
echo "  crystools — uninstalled"
echo ""
