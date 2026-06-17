# Cursor Integration

## Setup

1. Clone or copy Rolos AI Development Studio into your project.
2. Ensure `.cursor/rules/` exists with the six rule files.
3. Open the project in Cursor — rules load automatically.

## Rules Map

| Cursor Rule | Canonical Standard |
|-------------|-------------------|
| `project-structure.mdc` | `.ai/` layout (always applied) |
| `rails.mdc` | `.ai/standards/rails-development.md` |
| `aws.mdc` | `.ai/standards/aws-infrastructure.md` |
| `security.mdc` | `.ai/standards/security.md` |
| `database.mdc` | `.ai/standards/mysql.md` |
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

## Customization

Add project-specific rules in `.cursor/rules/` that **reference** `.ai/standards/` — do not copy standard text into Cursor rules.
