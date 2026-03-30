---
name: statusline
description: Configure Claude Code status line with context, git, cost, rate limits, and cache info. Use when the user wants to set up, update, or fix their status line. Triggers on "statusline", "status line", "status bar", "barra de estado".
user-invocable: true
author: Crystian
license: MIT
metadata:
  version: 0.1.1
  tags: statusline, status-bar, ui, productivity
  github: https://github.com/crystian/skills
  linkedin: https://www.linkedin.com/in/crystian
---

# Status Line Setup

Configures Claude Code's status line to display real-time session info in a two-line powerline-style layout.

## What it shows

**Line 1:** context window usage (progress bar) | directory | git branch + dirty/clean + ahead/behind + diff stats | session duration (total + API)

**Line 2:** rate limit 5h (progress bar + reset countdown) | model + context size | cost USD | cache tokens w/r | spinner

## Icon modes

Controlled by the `STATUSLINE_ICONS` env var in `~/.claude/settings.json`:

| Value   | Description                          |
|---------|--------------------------------------|
| `nerd`  | Nerd Font icons (requires a Nerd Font terminal) |
| `emoji` | Unicode emoji fallback (default)     |
| `none`  | Plain text, no icons                 |

## Setup procedure

When the user asks to set up, install, or configure the status line:

1. **Find the script path** — resolve the absolute path to `statusline-command.sh` in this skill's directory:
   ```bash
   SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/statusline-command.sh"
   ```
   Since this runs inside a plugin, the script lives at `skills/statusline/statusline-command.sh` relative to the plugin root. Find the actual installed path by searching for the file:
   ```bash
   find ~/.claude -path "*/crystools/skills/statusline/statusline-command.sh" 2>/dev/null | head -1
   ```
   If not found via `~/.claude`, search the known plugins directory or ask the user for the plugin location.

2. **Read current settings** from `~/.claude/settings.json`.

3. **Set the `statusLine` config**:
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "bash <ABSOLUTE_PATH_TO_SCRIPT>"
     }
   }
   ```

4. **Set the icon mode** (if not already set) — ask the user which mode they prefer (`nerd`, `emoji`, or `none`):
   ```json
   {
     "env": {
       "STATUSLINE_ICONS": "nerd"
     }
   }
   ```

5. **Write the updated settings** back to `~/.claude/settings.json`, preserving all existing keys.

6. **Verify** — confirm the setup is complete and tell the user to restart Claude Code to see the status line.

## Uninstall

To remove: delete the `statusLine` key and the `STATUSLINE_ICONS` env var from `~/.claude/settings.json`.

## Requirements

- `jq` must be installed (used by the script to parse JSON input)
- `git` for branch/status info
- A Nerd Font-compatible terminal if using `nerd` icon mode
