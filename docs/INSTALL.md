# Installing RoR Command Center

This guide explains how to add the framework to a new or existing project using the `install.sh` script.

> This is **Path A** (use with a cloud IDE like Cursor or Claude Code). It does
> **not** install Ollama. To run the specialist team locally with no cloud and no
> API keys, see [Local AI with Ollama](integrations/ollama.md) (`setup.sh` + the
> `rorcc` CLI) — and check your machine first with `bash scripts/check-machine.sh`.

For a beginner walkthrough of all routes (A / Ollama / Docker), see the
[User Manual](USER-MANUAL.md). Documentation map: [docs/README.md](README.md).

## Prerequisites

- Git and Bash
- (Optional) `@anthropic-ai/claude-code` for Claude Code
- (Optional) Python 3 (and `jq` for the Claude hooks) — both the Cursor (`.cursor/hooks.json`) and Claude hooks degrade gracefully if missing

## Step 1 — Clone the framework

```bash
git clone https://github.com/Rohega/ror-command-center.git
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

- **Cursor:** rules in `.cursor/rules/` load automatically. `project-structure.mdc`, `minimalism.mdc`, and `workflow-gates.mdc` are always applied (the last points at the proportional DoD in `.ai/standards/orchestration.md`). `.cursor/hooks.json` adds hard gates (blocks direct push to `main`, flags staged secrets).
- **Claude Code:** run `claude` — `CLAUDE.md` loads the standards and collaboration protocol. Codex / Copilot load `AGENTS.md`.
- **Other platforms:** see [integrations/](integrations/) (Codex, ChatGPT, Copilot, Gemini).
- **Daily use:** [User Manual](USER-MANUAL.md), [how to use agents](how-to/use-agents.md),
  and [how to run a workflow](how-to/run-workflows.md).

## Step 5 — Preview a workflow (no model)

From the project you just installed (or this clone), you can see the
`new-feature` phases without Ollama or API keys **if** the `rorcc` CLI is on
your `PATH` (`./install.sh --install-cli`):

```bash
cd /path/to/your-project
rorcc workflow new-feature --plan
```

Expect `LLM calls performed: 0`. In a project without `app/models` or
`config/deploy.rb`, the last lines are typically `Declared units: 14` /
`Selected units: 12` (two reviews omitted).

Without the CLI, paste this into Cursor / Claude Agent chat instead:

```
Execute .ai/workflows/new-feature.yaml for "<feature>". Stop after each phase
and wait for my approval.
```

Full flags (`--auto`, `--only`, `--skip`, `--full`): [how-to/run-workflows.md](how-to/run-workflows.md).

## Options

| Flag | Effect |
|------|--------|
| `--dry-run` | Show planned actions without writing files |
| `--force` | Overwrite files that already exist in the target |
| `--backup` | Save conflicting files as `<file>.bak` before overwriting |
| `--with-examples` | Also copy `examples/` and the warehouse-mvp example docs |
| `--install-cli` | Link the `rorcc` CLI into your PATH (for local Ollama use) and exit — no `<target-dir>` required |
| `-h`, `--help` | Show usage |

### Examples

```bash
# Install next to the framework clone
./install.sh ../my-rails-app

# Overwrite existing framework files, keeping backups
./install.sh --force --backup ~/projects/my-app

# Include the warehouse example for reference
./install.sh --with-examples ~/projects/my-app

# Install only the rorcc CLI (Path B / Ollama local use)
./install.sh --install-cli
```

## What gets installed

**Framework core (generic, reusable)** — matches `CORE_ITEMS` in `install.sh`:

- `.ai/` — single source of truth (agents, skills, workflows, standards, templates)
- `.cursor/` — Cursor adapter (`rules/`, `hooks.json`, `hooks/`)
- `.claude/` — Claude Code adapter (`agents/`, `hooks/`, `skills/`, `settings.json`)
- `AGENTS.md` — entry point for Codex, Copilot, and other AGENTS.md-aware tools
- `CLAUDE.md` — Claude Code entry point
- `docs/integrations/` — per-platform setup guides
- `docs/how-to/` — task-oriented how-tos (use agents, run workflows, create specialist, …)
- `docs/CLAUDE.md` — docs directory index for agents
- `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` — collaboration protocol examples
- `docs/USER-MANUAL.md` — human onboarding hub
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
