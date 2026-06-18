# Rolos AI Development Studio — Claude Code Adapter

Vendor-neutral AI engineering framework. **Canonical definitions live in `.ai/`** — this file is the Claude Code entry point only.

## Single Source of Truth

| Path | Purpose |
|------|---------|
| `.ai/agents/` | Role definitions (YAML) |
| `.ai/skills/` | Reusable capabilities |
| `.ai/workflows/` | End-to-end processes |
| `.ai/standards/` | Engineering rules |
| `.ai/templates/` | Document templates |

## Collaboration Protocol

@.ai/standards/collaboration.md

Full examples: `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md`

## Standards

@.ai/standards/stacks/rails/development.md
@.ai/standards/stacks/rails/frontend.md
@.ai/standards/ux-accessibility.md
@.ai/standards/aws-infrastructure.md
@.ai/standards/stacks/rails/mysql.md
@.ai/standards/security.md
@.ai/standards/testing.md
@.ai/standards/git-workflow.md

## Claude Adapters

- Agents: `.claude/agents/` → delegate to `.ai/agents/*.yaml`
- Skills: `.claude/skills/` → delegate to `.ai/skills/*/SKILL.md`
- Hooks: `.claude/hooks/`

## Getting Started

1. Read `.ai/workflows/new-feature.yaml` for the default development flow
2. Invoke skills with `/create-feature-spec`, `/qa-plan`, etc.
3. Spawn agents per task — definitions in `.ai/agents/`

See `docs/integrations/claude-code.md` for full setup.
