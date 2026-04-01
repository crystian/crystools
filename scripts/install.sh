#!/usr/bin/env bash
# crystools — install status line into ~/.claude/settings.json

set -euo pipefail

SETTINGS="$HOME/.claude/settings.json"
ICON_MODE="${1:-emoji}"

# Validate icon mode
case "$ICON_MODE" in
  nerd|emoji|none) ;;
  *) echo "Invalid icon mode: $ICON_MODE (use: nerd, emoji, none)"; exit 1 ;;
esac

# Require jq
if ! command -v jq &>/dev/null; then
  echo "jq not found — install it: https://jqlang.github.io/jq/download/"
  exit 1
fi

# Resolve plugin root from this script's own location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
PLUGIN_JSON="$PLUGIN_ROOT/.claude-plugin/plugin.json"

if [ ! -f "$PLUGIN_JSON" ]; then
  echo "Error: plugin.json not found at $PLUGIN_JSON"
  exit 1
fi
SCRIPT_PATH="$PLUGIN_ROOT/scripts/statusline-command.sh"

if [ ! -f "$SCRIPT_PATH" ]; then
  echo "Error: statusline-command.sh not found at $SCRIPT_PATH"
  exit 1
fi

# Replace $HOME with ~ for the command path
SCRIPT_PATH_SHORT=$(echo "$SCRIPT_PATH" | sed "s|$HOME|~|")

# Read version
VERSION=$(jq -r '.version' "$PLUGIN_JSON" 2>/dev/null || echo "unknown")

# Ensure settings.json exists
if [ ! -f "$SETTINGS" ]; then
  echo "{}" > "$SETTINGS"
fi

# Write statusLine + env.CRYSTOOLS_SL_ICONS (preserve everything else)
jq --arg cmd "bash $SCRIPT_PATH_SHORT" --arg icons "$ICON_MODE" '
  .statusLine = { type: "command", command: $cmd } |
  .env = (.env // {} | .CRYSTOOLS_SL_ICONS = $icons)
' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"

echo ""
echo "  crystools v${VERSION} — installed"
echo ""
