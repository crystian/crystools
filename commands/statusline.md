---
name: crystools-statusline
description: Configure Claude Code status line with context, git, cost, rate limits, and cache info.
allowed-tools: Bash(bash:*), Bash(cat:*), Read, AskUserQuestion
metadata:
  version: 0.2.15
---
                     
# Status Line Setup

**IMPORTANT: Do NOT use or spawn the `statusline-setup` agent. All steps must be executed directly in this command.**

Your **very first output** to the user MUST be:

```
crystools v{version} — status line setup
```

where `{version}` is the value of `metadata.version` from this file's YAML frontmatter (above, between the `---` lines). Do NOT search for it elsewhere. Do NOT run any command to find it. It is already in this document.

Do NOT skip this. This applies to EVERY path (install, reinstall, config, uninstall, help).

Then read `~/.claude/settings.json` and check if a `statusLine` key exists.

**RULE: After showing the version line, your next output to the user must be ONLY one of these:**
- The AskUserQuestion (if already installed)
- The install info block (if not installed)
**Nothing else. No status messages. No explanations about what you found.**

If it exists and the command contains "crystools/*/statusline-command.sh":

**Update check**: Extract the version number from the `statusLine.command` path (the segment between `crystools/` and `/scripts/`, e.g. `0.2.4`). Compare it with `metadata.version` from this file's frontmatter. If they differ, output:

```
⬆ Updated! v{installed_version} → v{current_version}
```

Then use AskUserQuestion:

- question: "A new version is available. Update now?"
- header: "Update"
- options:
  - label: "Update", description: "Reinstall with the new version"
  - label: "Cancel", description: "Keep current version"

If **Update**: proceed to the icon mode question and install flow (see below).
If **Cancel**: stop.

If the versions match (no update), use AskUserQuestion:

- question: "crystools status line is already installed. What do you want to do?"
- header: "Action"
- options:
  - label: "Reinstall", description: "Reconfigure from scratch"
  - label: "Config", description: "Change icon mode"
  - label: "Uninstall", description: "Remove status line"
  - label: "Help", description: "Show preview and segment descriptions"

If **Help**: show the preview and segment descriptions (see Help section below). Then stop.

If **Config**: show the current `CRYSTOOLS_SL_ICONS` value from `env` in `~/.claude/settings.json`, then ask icon mode with AskUserQuestion (see icon mode question below). Once the user picks, update `CRYSTOOLS_SL_ICONS` inside the `env` object in `~/.claude/settings.json` using the Edit tool directly on the JSON file. Do NOT use environment variables or export commands. Preserve all other keys. Confirm the change. Stop.

If **Uninstall**: find and run the uninstall script:

```bash
find ~/.claude -name "uninstall.sh" -path "*crystools/scripts/*" 2>/dev/null | sort -V | tail -1
```

```bash
bash <RESOLVED_PATH_TO_UNINSTALL.SH>
```

Show the output and stop.

If it exists but does NOT contain "crystools/scripts/statusline-command.sh", tell the user a different status line is configured and it will be replaced. Ask only: continue or cancel. If the user says no, stop.

If the user says yes, reinstall, or there was no existing statusLine:

Inform the user:

> This command will configure your Claude Code status line by modifying `~/.claude/settings.json`.
> It will point to a bash script (`statusline-command.sh`) bundled with this plugin that runs on every status line refresh.
> You can review the script source here: https://github.com/crystian/crystools/blob/main/scripts/statusline-command.sh
> You will be asked for permission before any file is modified.

Then show the preview:

```
 🪟 [▓▓▓32%-------]  📁 myproject  ⎇ main 󰄬 +12 -3  🕐 00:12:34 (00:08:21)
 ⏳[12%--------]  🤖 Opus 4.6 1M  💲 1.23  🔄 TK Cached w/r: 45/120  ⠋
```

## Icon mode question

Ask with AskUserQuestion:

- question: "Which icon mode do you prefer?"
- header: "Icons"
- options:
  - label: "Nerd", description: "Nerd Font icons (requires a Nerd Font terminal)"
  - label: "Emoji (Recommended)", description: "Unicode emoji fallback"
  - label: "None", description: "Plain text, no icons"

## Install

Once the user picks icon mode, find the install script:

```bash
find ~/.claude -name "install.sh" -path "*crystools/scripts/*" 2>/dev/null | sort -V | tail -1
```

**NEVER fabricate or guess paths** — only use the result of this command.

Then execute it with the chosen icon mode (nerd, emoji, or none):

```bash
bash <RESOLVED_PATH_TO_INSTALL.SH> <icon_mode>
```

Show the script output to the user. Do NOT add any extra commentary, summary, or instructions after the output. Do NOT tell the user to restart.

## Help

Show the preview:

```
 🪟 [▓▓▓32%-------]  📁 myproject  ⎇ main 󰄬 +12 -3  🕐 00:12:34 (00:08:21)
 ⏳[12%--------]  🤖 Opus 4.6 1M  💲 1.23  🔄 TK Cached w/r: 45/120  ⠋
```

Then explain what each segment shows:
- 🪟 **Context window** — usage progress bar with color thresholds (green < 50%, yellow < 75%, red >= 75%)
- 📁 **Directory** — smart project path (deep paths show `project/…/current`)
- ⎇ **Git** — branch name, dirty/clean indicator, ahead/behind upstream, lines added/removed
- 🕐 **Duration** — session wall time + API time in parentheses
- ⏳ **Rate limit** — 5-hour usage bar with reset countdown
- 🤖 **Model** — current model + context window size
- 💲 **Cost** — running session cost in USD
- 🔄 **Cache** — tokens written/read from cache
