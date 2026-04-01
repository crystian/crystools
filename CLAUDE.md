# Crystools Plugin

## Project Overview

Claude Code plugin with productivity tools: status line, utilities, and workflow enhancements.

## Repository Structure

```
.claude-plugin/
  plugin.json       — plugin manifest (name, version, description)
commands/           — slash commands (auto-discovered)
  <name>.md         — command definition (frontmatter + instructions)
scripts/            — supporting scripts referenced by commands
hooks/
  pre-commit        — interactive version bump for plugin.json
setup.sh            — configures git to use hooks/ directory
```


## Version Management

Versions are managed via the pre-commit hook — it prompts for patch/minor/major bump on each commit and updates `.claude-plugin/plugin.json`. Never bump versions manually or programmatically outside this hook.

## Pre-commit Hook

The hook at `hooks/pre-commit` is interactive (reads from `/dev/tty`) — it cannot run in non-interactive contexts. When committing from Claude Code, the user will need to handle the interactive prompt or skip with `s`.

## Git

**NEVER run `git push`.** Pushing is done manually by the user.

**NEVER commit automatically.** Do NOT commit after finishing work unless the user explicitly asks. Completing tasks ≠ commit.
