# Cursor Integration

## Setup

1. Clone or copy RoR Command Center into your project.
2. Ensure `.cursor/rules/` exists with the fifteen rule files.
3. Open the project in Cursor — rules load automatically.

## Rules Map

| Cursor Rule | Canonical Standard |
|-------------|-------------------|
| `project-structure.mdc` | `.ai/` layout (always applied) |
| `rails.mdc` | `.ai/standards/development.md` |
| `frontend.mdc` | `.ai/standards/frontend.md` |
| `ux-accessibility.mdc` | `.ai/standards/ux-accessibility.md` |
| `api-design.mdc` | `.ai/standards/api-design.md` |
| `testing.mdc` | `.ai/standards/testing.md` |
| `aws.mdc` | `.ai/standards/aws-infrastructure.md` |
| `security.mdc` | `.ai/standards/security.md` |
| `database.mdc` | `.ai/standards/postgresql.md`, `.ai/standards/mysql.md` |
| `sidekiq.mdc` | `.ai/standards/sidekiq-activejob.md` |
| `devise.mdc` | `.ai/standards/devise-auth.md` |
| `activeadmin.mdc` | `.ai/standards/activeadmin.md` |
| `hotwire.mdc` | `.ai/standards/hotwire.md` |
| `kamal.mdc` | `.ai/standards/kamal-docker.md` |
| `documentation.mdc` | `.ai/standards/documentation.md` |

## Invoking Skills

In chat, reference canonical skills explicitly:

```
Follow .ai/skills/create-feature-spec/SKILL.md to draft a feature spec for [idea].
```

## Invoking Agents

```
Act as the agent defined in .ai/agents/rails-architect.yaml. Review this design.
```

## Workflows

```
Execute .ai/workflows/new-feature.yaml starting at phase "architecture".
```

## Examples — Telling the Agent to Use These Guides

The rules in `.cursor/rules/` load automatically, but for skills, agents, and
workflows you point the agent at the canonical file in `.ai/`. Copy-paste prompts:

### 1. Draft a feature spec (skill + agent)

```
Act as the agent in .ai/agents/product-owner.yaml and follow
.ai/skills/create-feature-spec/SKILL.md to draft a spec for "multi-warehouse stock transfer".
Ask me questions first, then save it to docs/specs/stock-transfer.md.
```

### 2. Review a model against the standards (agent + standard)

```
Act as the agent in .ai/agents/qa-engineer.yaml. Review app/models/invoice.rb
against .ai/standards/development.md and .ai/standards/security.md.
List issues by severity; do not edit files yet.
```

### 3. Run the full new-feature workflow (workflow)

```
Execute .ai/workflows/new-feature.yaml for "multi-warehouse stock transfer".
Stop after each phase and wait for my approval before continuing.
```

### 4. Architecture decision (agent + template)

```
Act as the agent in .ai/agents/rails-architect.yaml. Using the template
.ai/templates/architecture-decision-record.md, propose an ADR for choosing
between Sidekiq and Solid Queue. Save it to docs/architecture/adr-0001-job-backend.md.
```

### 5. Make the agent always honor the framework (project rule)

To avoid repeating yourself, the always-applied rule
`.cursor/rules/project-structure.mdc` already tells the agent that `.ai/` is the
single source of truth. You can reinforce it per-chat with:

```
For this project, treat .ai/ as the source of truth. Before implementing,
load the relevant agent from .ai/agents/, the skill from .ai/skills/, and the
standards from .ai/standards/. Follow the collaboration protocol: ask, present
options, draft, and wait for my approval before writing files.
```

> Tip: use Cursor's `@`-mentions to attach the exact file, e.g.
> `@.ai/skills/create-feature-spec/SKILL.md`, so the agent reads it directly.

## Customization

Add project-specific rules in `.cursor/rules/` that **reference** `.ai/standards/` — do not copy standard text into Cursor rules.
