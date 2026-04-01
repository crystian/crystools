# Crystools Plugin

## Project Overview

Claude Code plugin with productivity tools: status line, utilities, and workflow enhancements.

## Repository Structure

```
.claude-plugin/
  plugin.json       — plugin manifest (name, version, description)
.github/workflows/
  bump-version.yml  — GitHub Actions auto version bump on push to main
commands/           — slash commands (auto-discovered)
  <name>.md         — command definition (frontmatter + instructions)
scripts/            — supporting scripts referenced by commands
```


## Version Management

Versions are managed via GitHub Actions (`.github/workflows/bump-version.yml`). On every push to main, the workflow auto-bumps patch version in `plugin.json`, `skills/*/SKILL.md`, and `commands/*.md`. Can also be triggered manually for minor/major bumps via workflow_dispatch. Never bump versions manually.

## Git

**NEVER run `git push`.** Pushing is done manually by the user.

**NEVER commit automatically.** Do NOT commit after finishing work unless the user explicitly asks. Completing tasks ≠ commit.
