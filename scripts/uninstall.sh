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

# Remove statusLine + crystools hooks + env.CRYSTOOLS_SL_ICONS (preserve everything else)
jq '
  del(.statusLine)
  | if .env then .env |= del(.CRYSTOOLS_SL_ICONS) | if .env == {} then del(.env) else . end else . end
  | if .hooks then
      .hooks.PreToolUse    = ((.hooks.PreToolUse    // []) | map(select(.crystools != true)))
      | .hooks.PostToolUse  = ((.hooks.PostToolUse   // []) | map(select(.crystools != true)))
      | .hooks.SessionStart = ((.hooks.SessionStart  // []) | map(select(.crystools != true)))
      | .hooks.SessionEnd   = ((.hooks.SessionEnd    // []) | map(select(.crystools != true)))
      | if (.hooks.PreToolUse    | length) == 0 then del(.hooks.PreToolUse)    else . end
      | if (.hooks.PostToolUse   | length) == 0 then del(.hooks.PostToolUse)   else . end
      | if (.hooks.SessionStart  | length) == 0 then del(.hooks.SessionStart)  else . end
      | if (.hooks.SessionEnd    | length) == 0 then del(.hooks.SessionEnd)    else . end
      | if .hooks == {} then del(.hooks) else . end
    else . end
' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"

echo ""
echo "  crystools — uninstalled"
echo ""
