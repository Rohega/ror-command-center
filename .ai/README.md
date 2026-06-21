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

## Non-negotiable gates (Definition of Done)

Every task — even greenfield — must satisfy these before it is "done". The Cursor
adapter enforces them via the always-applied rule `.cursor/rules/workflow-gates.mdc`.

- **Tests (RSpec)** cover the critical paths — [standards/testing.md](standards/testing.md)
- **Review** — `ponytail-review`, `review-rails-models`, `review-db-migrations`
- **QA sign-off** — skill `qa-plan`, no BLOCKING findings
- **Documentation** — skill `document-module`

**New apps bootstrap the test stack first** (RSpec + FactoryBot + SimpleCov +
generators): [standards/project-bootstrap.md](standards/project-bootstrap.md).

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
- Minimalism — lazy senior engineer ([standards/minimalism.md](standards/minimalism.md)): YAGNI, stdlib/Rails-native first, deletion over addition, never cutting safety. Skills: `ponytail-review`, `ponytail-audit`, `ponytail-debt`.
