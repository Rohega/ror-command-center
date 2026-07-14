# Google Gemini Integration

> **Depth:** starter (workspace instructions). For full recipes and workflows use
> [cursor.md](cursor.md), [claude-code.md](claude-code.md), or [../how-to/run-workflows.md](../how-to/run-workflows.md).

## Gemini Code Assist / Workspace

Add to project or workspace instructions:

```
Project uses RoR Command Center (.ai/ directory).

Before implementing:
1. Read .ai/standards/collaboration.md
2. Identify agent (.ai/agents/) and skill (.ai/skills/)
3. Ask clarifying questions; present options; wait for approval before changes

Stack: Ruby on Rails 7+/8+, PostgreSQL & MySQL, Sidekiq/ActiveJob, Devise, ActiveAdmin, Hotwire, React/Inertia, AWS, Docker, Capistrano, Kamal.
```

## Context Files

Pin in workspace:
- `.ai/README.md`
- `.ai/standards/development.md`
- `.ai/standards/security.md`
- Active workflow from `.ai/workflows/`

## Multi-file Edits

Gemini can edit multiple files — still require explicit user approval per collaboration standard.
