# RoR Command Center — Canonical Index

This directory is the **single source of truth** for all Ruby on Rails AI engineering definitions. Platform entry files (`AGENTS.md`, `CLAUDE.md`) and platform-specific folders (`.cursor/`, `.claude/`) are adapters only — they reference files here and must not duplicate content.

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
2. Preview it without a model: `rorcc workflow new-feature --plan`
   (human how-to: [docs/how-to/run-workflows.md](../docs/how-to/run-workflows.md))
3. Load collaboration rules: [standards/collaboration.md](standards/collaboration.md)
4. Invoke the first skill: [skills/create-feature-spec/SKILL.md](skills/create-feature-spec/SKILL.md)

## Definition of Done (proportional)

Canonical: [standards/orchestration.md](standards/orchestration.md).
**Artifacts are earned by complexity, risk, or uncertainty.**

Never skip security, trust-boundary validation, data-loss protection, tests for
non-trivial logic, or migration review when migrations exist. Do skip Feature
Spec / Stories / ADR / module docs / full QA on size-S local changes.

The Cursor adapter (`.cursor/rules/workflow-gates.mdc`) points here — it must
not re-impose a uniform 8-phase checklist.

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
| `delegation.use_proactively` | Capability hint; native orchestration may suppress handoff when the router did not earn it |
| `delegation.readonly` | Cursor subagent `readonly` flag |
| `delegation.pairs_with_skills` | Skills this role typically runs |

**Compile rule:** `.cursor/agents/<id>.md` and `.claude/agents/<id>.md` are thin
adapters — they compile `delegation` into frontmatter `description` and point
back to `.ai/agents/<id>.yaml`. Descriptions are discovery metadata, not
permission to bypass the Task Router. Runtime behavior is governed by
[standards/native-agent-orchestration.md](standards/native-agent-orchestration.md).

## Core Philosophy

- Rails First
- Convention Over Configuration
- Production Ready
- AWS Native
- Maintainable Code
- Testable Code
- Senior Engineer Standards
- Minimalism — lazy senior engineer ([standards/minimalism.md](standards/minimalism.md)): YAGNI, stdlib/Rails-native first, deletion over addition, never cutting safety. Skills: `ponytail-review`, `ponytail-audit`, `ponytail-debt`.
- Orchestration — deterministic workflow router ([standards/orchestration.md](standards/orchestration.md)): classify impact once (optional), then select skills by `applies_when` + project paths. Never spend tokens to decide the next phase.
- Native agent orchestration — the Task Router decides **what** work exists; Cursor, Claude Code, Codex, and future runtimes decide **how** to execute only that selected work ([standards/native-agent-orchestration.md](standards/native-agent-orchestration.md)).
