# RoR Command Center — Claude Code Adapter

Production-grade Ruby on Rails AI engineering team. **Canonical definitions live in `.ai/`** — this file is the Claude Code entry point only.

This is **not** a generic agent framework. It accelerates real, production-grade Ruby on Rails development.

## Core Philosophy

Rails First · Convention Over Configuration · Production Ready · AWS Native · Maintainable Code · Testable Code · Senior Engineer Standards.

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

@.ai/README.md
@.ai/standards/development.md
@.ai/standards/project-bootstrap.md
@.ai/standards/minimalism.md
@.ai/standards/frontend.md
@.ai/standards/hotwire.md
@.ai/standards/ux-accessibility.md
@.ai/standards/aws-infrastructure.md
@.ai/standards/kamal-docker.md
@.ai/standards/postgresql.md
@.ai/standards/mysql.md
@.ai/standards/sidekiq-activejob.md
@.ai/standards/devise-auth.md
@.ai/standards/activeadmin.md
@.ai/standards/security.md
@.ai/standards/testing.md
@.ai/standards/git-workflow.md

## Claude Adapters

- Agents: `.claude/agents/` → delegate to `.ai/agents/*.yaml`
- Skills: `.claude/skills/` → delegate to `.ai/skills/*/SKILL.md`
- Hooks: `.claude/hooks/`

Cursor uses the same YAML via native subagents in `.cursor/agents/` (priority over `.claude/agents/` when names match).

## Getting Started

1. Read `.ai/workflows/new-feature.yaml` for the default development flow
2. Invoke skills with `/create-feature-spec`, `/qa-plan`, etc.
3. Spawn agents per task — definitions in `.ai/agents/`; Cursor adapters in `.cursor/agents/`

See `docs/integrations/claude-code.md` for full setup.
