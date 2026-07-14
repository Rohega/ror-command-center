# Claude Code Integration

How to use RoR Command Center inside Claude Code — setup, slash skills, recipes,
and troubleshooting. Depth status: **full** (aligned with the Cursor guide).

## Setup

1. Install [Claude Code](https://docs.anthropic.com/en/docs/claude-code).
2. Run `claude` from the project root (must contain `.ai/` after install).
3. Root `CLAUDE.md` loads standards and the collaboration protocol automatically.

## Concepts in 30 seconds

| Term | Where it lives | In plain words |
|------|----------------|----------------|
| **Standard** | `.ai/standards/` | How we build things |
| **Skill** | `.ai/skills/` (+ `.claude/skills/` slash adapter) | One concrete task |
| **Agent** | `.ai/agents/<id>.yaml` (+ `.claude/agents/<id>.md`) | Specialist role |
| **Workflow** | `.ai/workflows/` | Chained phases with gates |

## Architecture

| Layer | Path | Role |
|-------|------|------|
| Canonical | `.ai/` | Source of truth |
| Adapter | `.claude/agents/` | Thin wrappers → `.ai/agents/*.yaml` |
| Adapter | `.claude/skills/` | Slash commands → `.ai/skills/*/SKILL.md` |
| Adapter | `.claude/hooks/` | Git safety, session context |

## Planning vs implementing

Claude Code does not mirror Cursor’s Ask/Agent modes 1:1. Equivalent practice:

| Intent | What to do |
|--------|------------|
| Plan / review only | Say “ask questions and propose a plan; **do not edit files yet**” |
| Implement | Approve the draft, then allow writes (collaboration protocol still applies) |

## Slash commands (skills)

Adapters under `.claude/skills/`. Canonical bodies stay in `.ai/skills/`.

| Command | Canonical skill |
|---------|-----------------|
| `/create-feature-spec` | `create-feature-spec` |
| `/create-user-stories` | `create-user-stories` |
| `/create-ux-spec` | `create-ux-spec` |
| `/create-architecture-plan` | `create-architecture-plan` |
| `/create-api-endpoints` | `create-api-endpoints` |
| `/review-rails-models` | `review-rails-models` |
| `/review-db-migrations` | `review-db-migrations` |
| `/sql-review` | `sql-review` |
| `/security-audit` | `security-audit` |
| `/qa-plan` | `qa-plan` |
| `/ponytail-review` | `ponytail-review` |
| `/ponytail-audit` | `ponytail-audit` |
| `/ponytail-debt` | `ponytail-debt` |
| `/document-module` | `document-module` |
| `/document-user-guide` | `document-user-guide` |
| `/record-user-demo` | `record-user-demo` |
| `/reverse-document-legacy` | `reverse-document-legacy` |
| `/tech-debt-analysis` | `tech-debt-analysis` |
| `/aws-deploy-plan` | `aws-deploy-plan` |
| `/capistrano-review` | `capistrano-review` |
| `/nginx-puma-review` | `nginx-puma-review` |
| `/release-checklist` | `release-checklist` |
| `/ocr-pipeline` | `ocr-pipeline` |
| `/whatsapp-integration` | `whatsapp-integration` |

If a slash is missing in your install, re-run `./install.sh --force` or invoke by
path: `Follow .ai/skills/<name>/SKILL.md …`.

## Spawning agents

```
Read .ai/agents/security-reviewer.yaml and perform a security audit.
Ask questions first; do not edit files until I approve.
```

Or: “Act as the agent in `.ai/agents/rails-architect.yaml` …”

## Copy-paste recipes

### 1. Draft a feature spec

```
/create-feature-spec Draft a spec for "multi-warehouse stock transfer".
Ask me questions first, then save it to docs/specs/ under my approval.
```

### 2. Review a model (no edits yet)

```
Read .ai/agents/qa-engineer.yaml. Review app/models/invoice.rb against
.ai/standards/development.md and .ai/standards/security.md.
List issues by severity; do not edit files yet.
```

### 3. Run the full new-feature workflow

```
Execute .ai/workflows/new-feature.yaml for "multi-warehouse stock transfer".
Stop after each phase and wait for my approval. Use the agent YAML for each phase.
```

See also: [../how-to/run-workflows.md](../how-to/run-workflows.md).

### 4. Architecture ADR

```
Read .ai/agents/rails-architect.yaml. Using
.ai/templates/architecture-decision-record.md, propose an ADR for Sidekiq vs
Solid Queue. Draft only until I approve; then save under docs/architecture/.
```

### 5. Honor the framework this session

```
Treat .ai/ as the single source of truth. Before implementing, load the matching
agent under .ai/agents/, the skill under .ai/skills/, and relevant standards.
Follow collaboration: ask → options → draft → wait for my approval before writes.
```

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Skills / standards ignored | Session not at project root | `cd` to the app with `.ai/` and restart `claude` |
| Slash command missing | Adapter not installed | Re-run `install.sh --force`; or call `.ai/skills/…` by path |
| Edits without asking | Prompt didn’t forbid writes | Add “do not edit until I approve” (recipe planning row above) |
| Unsure which agent | — | [../how-to/use-agents.md](../how-to/use-agents.md) |
| Workflows skipped gates | Prompt too open-ended | Use recipe #3; require stop after each phase |

## Hooks

Configured in `.claude/settings.json`:

- Commit validation (secrets, JSON)
- Push warnings on protected branches
- Session start context
- Skill change advisory

## Updating skills

Edit **`.ai/skills/<name>/SKILL.md`** first. Update `.claude/skills/<name>/SKILL.md`
description only if the one-line summary changed.
