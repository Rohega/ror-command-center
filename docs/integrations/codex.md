# OpenAI Codex Integration

Codex does not read project files automatically. Load context explicitly at session start.

## Minimum Context

Paste or attach:

1. `.ai/standards/collaboration.md`
2. `.ai/standards/development.md`
3. The agent YAML: `.ai/agents/<role>.yaml`
4. The skill: `.ai/skills/<skill>/SKILL.md`

## Example Prompt

```
You are operating under RoR Command Center.

Collaboration: Question → Options → Decision → Draft → Approval. Ask before writing files.

Agent definition:
[paste .ai/agents/backend-rails-developer.yaml]

Skill:
[paste .ai/skills/create-api-endpoints/SKILL.md]

Task: Implement US-003 from docs/stories/...
```

## Workflows

Reference workflow YAML phases:

```
Follow .ai/workflows/new-feature.yaml from phase "review".
```

## CI / Automation

In CI pipelines, pass `.ai/skills/<name>/SKILL.md` as system context for automated review steps.
