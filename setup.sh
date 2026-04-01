#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION=$(jq -r '.version' "$SCRIPT_DIR/.claude-plugin/plugin.json" 2>/dev/null || echo "unknown")

LABEL="  crystools v${VERSION}  "
WIDTH=${#LABEL}
BORDER=$(printf '═%.0s' $(seq 1 "$WIDTH"))

echo ""
echo "  ╔${BORDER}╗"
echo "  ║${LABEL}║"
echo "  ╚${BORDER}╝"
echo ""

git config core.hooksPath hooks
echo "  ✔ Hooks installed (core.hooksPath → hooks/)"
echo ""
