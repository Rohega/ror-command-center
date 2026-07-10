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

How to use each one (what/when/how to invoke per platform):
[docs/how-to/use-agents.md](../docs/how-to/use-agents.md).

### Delegation schema

Each agent YAML includes additive discovery fields used by platform adapters:

| Field | Purpose |
|-------|---------|
| `id` | Stable slug (= filename = Cursor subagent `name`) |
| `delegation.summary` | One-line WHAT for adapter `description` |
| `delegation.use_when` | Trigger phrases for automatic delegation |
| `delegation.use_proactively` | Prefer proactive Task/subagent handoff |
| `delegation.readonly` | Cursor subagent `readonly` flag |
| `delegation.pairs_with_skills` | Skills this role typically runs |

**Compile rule:** `.cursor/agents/<id>.md` and `.claude/agents/<id>.md` are thin
adapters — they compile `delegation` into frontmatter `description` and point
back to `.ai/agents/<id>.yaml`. Do not duplicate role content in adapters.

## Core Philosophy

- Rails First
- Convention Over Configuration
- Production Ready
- AWS Native
- Maintainable Code
- Testable Code
- Senior Engineer Standards
- Minimalism — lazy senior engineer ([standards/minimalism.md](standards/minimalism.md)): YAGNI, stdlib/Rails-native first, deletion over addition, never cutting safety. Skills: `ponytail-review`, `ponytail-audit`, `ponytail-debt`.
