# RoR Command Center — Canonical Index

This directory is the **single source of truth** for all Ruby on Rails AI engineering definitions. Platform-specific folders (`.cursor/`, `.claude/`) are adapters only — they reference files here and must not duplicate content.

## Contents

| Directory | Description |
|-----------|-------------|
| [agents/](agents/) | 8 Rails specialist role definitions (YAML) |
| [skills/](skills/) | Reusable capabilities |
| [workflows/](workflows/) | End-to-end processes |
| [standards/](standards/) | Engineering rules |
| [templates/](templates/) | Document templates |

## Quick Start

1. Pick a workflow: [workflows/new-feature.yaml](workflows/new-feature.yaml)
2. Load collaboration rules: [standards/collaboration.md](standards/collaboration.md)
3. Invoke the first skill: [skills/create-feature-spec/SKILL.md](skills/create-feature-spec/SKILL.md)

## Agent Roster (8 specialists)

- product-owner, rails-architect, backend-rails-developer
- frontend-react-inertia-developer, aws-devops-engineer
- qa-engineer, documentation-writer, security-reviewer

## Core Philosophy

- Rails First
- Convention Over Configuration
- Production Ready
- AWS Native
- Maintainable Code
- Testable Code
- Senior Engineer Standards
