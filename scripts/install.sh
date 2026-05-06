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
HOOK_PATH="$PLUGIN_ROOT/scripts/agents-hook.sh"

if [ ! -f "$SCRIPT_PATH" ]; then
  echo "Error: statusline-command.sh not found at $SCRIPT_PATH"
  exit 1
fi

# Replace $HOME with ~ for the command path
SCRIPT_PATH_SHORT=$(echo "$SCRIPT_PATH" | sed "s|$HOME|~|")
HOOK_PATH_SHORT=$(echo "$HOOK_PATH" | sed "s|$HOME|~|")

# Read version
VERSION=$(jq -r '.version' "$PLUGIN_JSON" 2>/dev/null || echo "unknown")

# Ensure settings.json exists
if [ ! -f "$SETTINGS" ]; then
  echo "{}" > "$SETTINGS"
fi

# Write statusLine + hooks + env.CRYSTOOLS_SL_ICONS (preserve everything else).
# Hooks fed to agents-hook.sh:
#   PreToolUse + PostToolUse (matcher: Agent) → record subagent events
#   SessionStart                              → sweep orphan JSONL files
#   SessionEnd                                → drop this session's JSONL
# All tagged with "crystools": true so uninstall can find them.
jq --arg cmd "bash $SCRIPT_PATH_SHORT" \
   --arg hook_cmd "bash $HOOK_PATH_SHORT" \
   --arg icons "$ICON_MODE" '
  .statusLine = { type: "command", command: $cmd } |
  .env = (.env // {} | .CRYSTOOLS_SL_ICONS = $icons) |
  .hooks = (.hooks // {}) |
  .hooks.PreToolUse = (
    ((.hooks.PreToolUse // []) | map(select(.crystools != true))) +
    [{ crystools: true, matcher: "Agent", hooks: [{ type: "command", command: $hook_cmd }] }]
  ) |
  .hooks.PostToolUse = (
    ((.hooks.PostToolUse // []) | map(select(.crystools != true))) +
    [{ crystools: true, matcher: "Agent", hooks: [{ type: "command", command: $hook_cmd }] }]
  ) |
  .hooks.SessionStart = (
    ((.hooks.SessionStart // []) | map(select(.crystools != true))) +
    [{ crystools: true, hooks: [{ type: "command", command: $hook_cmd }] }]
  ) |
  .hooks.SessionEnd = (
    ((.hooks.SessionEnd // []) | map(select(.crystools != true))) +
    [{ crystools: true, hooks: [{ type: "command", command: $hook_cmd }] }]
  )
' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"

echo ""
echo "  crystools v${VERSION} — installed"
echo ""
