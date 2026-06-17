# Rolos AI Development Studio — Canonical Index

This directory is the **single source of truth** for all AI engineering definitions. Platform-specific folders (`.cursor/`, `.claude/`) are adapters only — they reference files here and must not duplicate content.

## Contents

| Directory | Files | Description |
|-----------|-------|-------------|
| [agents/](agents/) | 13 YAML | Role definitions |
| [skills/](skills/) | 15 skills | Reusable capabilities |
| [workflows/](workflows/) | 4 YAML | End-to-end processes |
| [standards/](standards/) | 10 MD | Engineering rules |
| [templates/](templates/) | 7 MD | Document templates |

## Quick Start

1. Pick a workflow: [workflows/new-feature.yaml](workflows/new-feature.yaml)
2. Load collaboration rules: [standards/collaboration.md](standards/collaboration.md)
3. Invoke the first skill: [skills/create-feature-spec/SKILL.md](skills/create-feature-spec/SKILL.md)

## Agent Roster

- product-owner, rails-architect, backend-rails-developer
- frontend-react-inertia-developer, aws-devops-engineer, mysql-dba
- security-reviewer, qa-engineer, documentation-writer
- odoo-specialist, textract-ocr-specialist, release-manager, code-reviewer

## Design Principles

- Rails conventions over custom abstractions
- Security by default
- Infrastructure as Code
- Documentation-driven development
- Testability first
- Simplicity over complexity
- Vendor-neutral architecture
