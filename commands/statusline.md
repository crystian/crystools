---
name: crystools-statusline
description: Configure Claude Code status line with context, git, cost, rate limits, and cache info.
allowed-tools: Bash(bash:*), Bash(cat:*), Read, AskUserQuestion
metadata:
  version: 0.2.18
---
                     
# Status Line Setup

**IMPORTANT: Do NOT use or spawn the `statusline-setup` agent. All steps must be executed directly in this command.**

Your **very first output** to the user MUST be:

```
crystools v{version} — status line setup
```

To get `{version}`, run:

```bash
find ~/.claude -name "plugin.json" -path "*crystools-statusline*" 2>/dev/null | sort -V | tail -1 | xargs jq -r .version
```

Use the EXACT output of that command. Do NOT guess, hallucinate, or read the version from any other source (not from the YAML frontmatter, not from file paths, not from settings.json).

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
 🪟[▓▓▓32%----]  📁 myproject  ⎇ main △ +12 -3  🕐 12:32:34 (08:28:21)
 ⏳[▓12%------]  🤖 Opus 4.6 1M  💲 1.23  🔄 TK Cached w/r: 45/120  ⠋
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

Show the preview and segment descriptions with ANSI colors matching the actual statusline. Run this command:

```bash
MODE=$(jq -r '.env.CRYSTOOLS_SL_ICONS // "emoji"' ~/.claude/settings.json 2>/dev/null || echo emoji)
case "$MODE" in
  nerd)  ctx='󰾆' csep=' ' dir='󰝰' git='󰘬' tm='󱑎' rt='󰔟 ' mdl='󱙺' cst='$' cch='󰑓' ;;
  emoji) ctx='🪟' csep='' dir='📁' git='⎇' tm='🕐' rt='⏳' mdl='🤖' cst='💲' cch='🔄' ;;
  *)     ctx='' csep='' dir='' git='' tm='' rt='' mdl='' cst='$' cch='' ;;
esac
printf '\033[38;2;0;200;255m %s%s[▓▓▓32%%\033[38;2;60;60;80m----\033[38;2;0;200;255m] \033[0m\033[38;2;220;190;130m %s myproject \033[0m\033[38;2;190;170;220m %s main △  \033[38;2;0;255;140m+12 \033[38;2;255;60;90m-3 \033[0m\033[38;2;160;210;200m %s 12:32:34 (08:28:21) \033[0m\n' "$ctx" "$csep" "$dir" "$git" "$tm"
printf '\033[38;2;0;255;180m %s[▓12%%\033[38;2;60;60;80m------\033[38;2;0;255;180m] \033[0m\033[38;2;210;170;190m %s Opus 4.6 1M \033[0m\033[38;2;170;210;170m %s 1.23 \033[0m\033[38;2;180;190;210m %s TK Cached w/r: 45/120 \033[0m\033[38;2;0;200;255m ⠋ \033[0m\n\n' "$rt" "$mdl" "$cst" "$cch"
printf '  \033[38;2;0;200;255m%sContext window\033[0m — usage progress bar (green < 50%%, yellow < 75%%, red >= 75%%)\n' "${ctx:+$ctx }"
printf '  \033[38;2;220;190;130m%sDirectory\033[0m — smart project path (deep paths show project/…/current)\n' "${dir:+$dir }"
printf '  \033[38;2;190;170;220m%sGit\033[0m — branch, dirty/clean, ahead/behind, lines +/-\n' "${git:+$git }"
printf '  \033[38;2;160;210;200m%sDuration\033[0m — session wall time + API time in parentheses\n' "${tm:+$tm }"
printf '  \033[38;2;0;255;180m%sRate limit\033[0m — 5-hour usage bar with reset countdown\n' "${rt:+${rt% } }"
printf '  \033[38;2;210;170;190m%sModel\033[0m — current model + context window size\n' "${mdl:+$mdl }"
printf '  \033[38;2;170;210;170m%sCost\033[0m — running session cost in USD\n' "${cst:+$cst }"
printf '  \033[38;2;180;190;210m%sCache\033[0m — tokens written/read from cache\n' "${cch:+$cch }"
```

After running, do NOT re-output the result — the tool output is already visible to the user with proper ANSI colors.
