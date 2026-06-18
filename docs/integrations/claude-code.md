# Claude Code Integration

## Setup

1. Install [Claude Code](https://docs.anthropic.com/en/docs/claude-code).
2. Run `claude` from the project root.
3. `CLAUDE.md` loads automatically.

## Architecture

| Layer | Path | Role |
|-------|------|------|
| Canonical | `.ai/` | Source of truth |
| Adapter | `.claude/agents/` | Thin wrappers → `.ai/agents/*.yaml` |
| Adapter | `.claude/skills/` | Slash commands → `.ai/skills/*/SKILL.md` |
| Adapter | `.claude/hooks/` | Git safety, session context |

## Slash Commands

| Command | Canonical Skill |
|---------|-----------------|
| `/create-feature-spec` | `.ai/skills/create-feature-spec/SKILL.md` |
| `/create-user-stories` | `.ai/skills/create-user-stories/SKILL.md` |
| `/create-ux-spec` | `.ai/skills/create-ux-spec/SKILL.md` |
| `/create-architecture-plan` | `.ai/skills/create-architecture-plan/SKILL.md` |
| `/review-rails-models` | `.ai/skills/review-rails-models/SKILL.md` |
| `/review-db-migrations` | `.ai/skills/review-db-migrations/SKILL.md` |
| `/create-api-endpoints` | `.ai/skills/create-api-endpoints/SKILL.md` |
| `/security-audit` | `.ai/skills/security-audit/SKILL.md` |
| `/sql-review` | `.ai/skills/sql-review/SKILL.md` |
| `/aws-deploy-plan` | `.ai/skills/aws-deploy-plan/SKILL.md` |
| `/nginx-puma-review` | `.ai/skills/nginx-puma-review/SKILL.md` |
| `/capistrano-review` | `.ai/skills/capistrano-review/SKILL.md` |
| `/qa-plan` | `.ai/skills/qa-plan/SKILL.md` |
| `/release-checklist` | `.ai/skills/release-checklist/SKILL.md` |
| `/document-module` | `.ai/skills/document-module/SKILL.md` |
| `/tech-debt-analysis` | `.ai/skills/tech-debt-analysis/SKILL.md` |

## Spawning Agents

Use the Task tool or ask Claude to adopt an agent:

```
Read .ai/agents/security-reviewer.yaml and perform a security audit.
```

## Hooks

Configured in `.claude/settings.json`:
- Commit validation (secrets, JSON)
- Push warnings on protected branches
- Session start context
- Skill change advisory

## Updating Skills

Edit **`.ai/skills/<name>/SKILL.md`** first. Update `.claude/skills/<name>/SKILL.md` description only if the one-line summary changed.
