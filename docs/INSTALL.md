# Installing RoR Command Center

This guide explains how to add the framework to a new or existing project using the `install.sh` script.

## Prerequisites

- Git and Bash
- (Optional) `@anthropic-ai/claude-code` for Claude Code
- (Optional) `jq` and Python 3 for the git hooks — they degrade gracefully if missing

## Step 1 — Clone the framework

```bash
git clone <repo-url> ror-command-center
cd ror-command-center
```

## Step 2 — Preview the install (recommended)

Run a dry run first to see exactly what will be copied into your project, without writing anything:

```bash
./install.sh --dry-run /path/to/your-project
```

## Step 3 — Install into your project

```bash
./install.sh /path/to/your-project
```

The target directory is created if it does not exist. Existing files are **skipped** by default so your project is never clobbered.

## Step 4 — Open your project

```bash
cd /path/to/your-project
```

- **Cursor:** rules in `.cursor/rules/` load automatically. `project-structure.mdc` is always applied.
- **Claude Code:** run `claude` — `CLAUDE.md` loads the standards and collaboration protocol.
- **Other platforms:** see [integrations/](integrations/) (Codex, ChatGPT, Copilot, Gemini).

## Options

| Flag | Effect |
|------|--------|
| `--dry-run` | Show planned actions without writing files |
| `--force` | Overwrite files that already exist in the target |
| `--backup` | Save conflicting files as `<file>.bak` before overwriting |
| `--with-examples` | Also copy `examples/` and the warehouse-mvp example docs |
| `-h`, `--help` | Show usage |

### Examples

```bash
# Install next to the framework clone
./install.sh ../my-rails-app

# Overwrite existing framework files, keeping backups
./install.sh --force --backup ~/projects/my-app

# Include the warehouse example for reference
./install.sh --with-examples ~/projects/my-app
```

## What gets installed

**Framework core (generic, reusable):**

- `.ai/` — single source of truth (agents, skills, workflows, standards, templates)
- `.cursor/` — Cursor adapter (`rules/`)
- `.claude/` — Claude Code adapter (`agents/`, `hooks/`, `skills/`, `settings.json`)
- `CLAUDE.md` — Claude Code entry point
- `docs/integrations/` — per-platform setup guides
- `docs/CLAUDE.md`, `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md`
- `.github/copilot-instructions.md`

**Empty scaffolding** (created with a `.gitkeep`, no example content):

- `docs/architecture/`, `docs/specs/`, `docs/stories/`, `docs/design/`, `docs/runbooks/`, `docs/modules/`

## What is excluded

- `examples/`, `archive/`, `production/`, `.git/`
- Repo meta files: `README.md`, `CONTRIBUTING.md`, `UPGRADING.md`, `SECURITY.md`, `LICENSE`, `.github/FUNDING.yml`, `.github/CODEOWNERS`
- Warehouse-mvp example docs (unless `--with-examples`)
- `.claude/settings.local.json` (local-only)

## Re-syncing the framework later

When the framework gets updates, pull them and re-run the installer with `--force` to refresh the framework files. Use `--backup` to keep copies of anything you customized:

```bash
cd ror-command-center
git pull
./install.sh --force --backup /path/to/your-project
```

Your project-specific docs (under `docs/architecture/`, `docs/specs/`, etc.) are never overwritten because the installer only creates those folders when empty.
