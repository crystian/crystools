---
description: Configure Claude Code status line with context, git, cost, rate limits, and cache info.
allowed-tools: Read, Edit, Bash(grep:*), Bash(find:*)
---

# Status Line Setup

First, read `~/.claude/settings.json` and check if `statusLine` is already configured.

## If already installed

Tell the user the status line is already configured and ask:
1. Reinstall (reconfigure)
2. Uninstall (remove status line)
3. Cancel

If **uninstall**: remove the `statusLine` key and the `STATUSLINE_ICONS` key from `env` in `~/.claude/settings.json`, preserving all other keys. Confirm removal and tell the user to restart Claude Code.

If **cancel**: do nothing and stop.

If **reinstall**: continue with the setup procedure below.

## If not installed

Inform the user:

> This command will configure your Claude Code status line by modifying `~/.claude/settings.json`.
> It will point to a bash script (`statusline-command.sh`) bundled with this plugin that runs on every status line refresh.
> You can review the script source here: https://github.com/crystian/crystools/blob/main/scripts/statusline-command.sh
> You will be asked for permission before any file is modified.

Wait for the user to confirm before proceeding. If the user declines, do nothing and stop.

## What the status line shows

**Line 1:** context window usage (progress bar) | directory | git branch + dirty/clean + ahead/behind + diff stats | session duration (total + API)

**Line 2:** rate limit 5h (progress bar + reset countdown) | model + context size | cost USD | cache tokens w/r | spinner

## Setup procedure

1. **Find the script path** — resolve the absolute path to `statusline-command.sh`:
   ```bash
   find ~/.claude -name "statusline-command.sh" -path "*/scripts/*" 2>/dev/null | head -1
   ```
   If not found, ask the user for the plugin location.

2. **Read current settings** from `~/.claude/settings.json`.

3. **Ask the user which icon mode they prefer** (if `STATUSLINE_ICONS` is not already set):

   | Value   | Description                          |
   |---------|--------------------------------------|
   | `nerd`  | Nerd Font icons (requires a [Nerd Font](https://www.nerdfonts.com/) terminal) |
   | `emoji` | Unicode emoji fallback (default)     |
   | `none`  | Plain text, no icons                 |

4. **Set the `statusLine` and `env` config** in `~/.claude/settings.json`, preserving all existing keys:
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "bash <ABSOLUTE_PATH_TO_SCRIPT>"
     },
     "env": {
       "STATUSLINE_ICONS": "<user_choice>"
     }
   }
   ```

5. **Confirm** the setup is complete and tell the user to restart Claude Code to see the status line.

## Uninstall

To remove: delete the `statusLine` key and the `STATUSLINE_ICONS` env var from `~/.claude/settings.json`.

## Requirements

- `jq` must be installed (used by the script to parse JSON input)
- `git` for branch/status info
- A Nerd Font-compatible terminal if using `nerd` icon mode
