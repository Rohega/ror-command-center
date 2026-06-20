# Contributing to RoR Command Center

RoR Command Center is a **production-grade Ruby on Rails AI engineering team**. Contributions welcome: new skills, agent improvements, standards updates, and adapter fixes.

## Architecture Rule

**`.ai/` is the single source of truth.** Platform folders (`.cursor/`, `.claude/`) must only reference `.ai/` — never duplicate full skill or agent content.

## What Makes a Good PR

- Bug fixes in adapters, hooks, or standards
- New skills that fill a workflow gap (add to `.ai/skills/` first)
- Agent definition improvements in `.ai/agents/*.yaml`
- Documentation corrections and integration guides
- Standards updates for Rails, AWS, MySQL, security

Feature requests: open an issue first.

**What this repo isn't:** Application code, client projects, or generated specs for a specific product. Keep those in your application repository.

## Adding a Skill

1. Create `.ai/skills/<name>/SKILL.md` with: purpose, inputs, outputs, execution steps, validation checklist
2. Add thin Claude adapter: `.claude/skills/<name>/SKILL.md` (frontmatter + pointer)
3. Reference agent in skill file if applicable
4. Update workflow YAML if part of a process

## Adding an Agent

1. Create `.ai/agents/<slug>.yaml` with full schema (name, purpose, responsibilities, inputs, outputs, rules, anti_patterns, success_criteria)
2. Add thin Claude adapter: `.claude/agents/<slug>.md`

## Branching (required)

`main` is protected: **no direct commits or pushes — PR only.** After cloning,
enable the local guardrail once:

```bash
git config core.hooksPath .githooks
```

This installs a `pre-commit` hook that blocks commits on `main`/`master`/`develop`.
Always work on a feature branch (`git switch -c feat/<slug>`). See
`.ai/standards/git-workflow.md`.

## Collaboration Protocol

All agents follow `.ai/standards/collaboration.md` — user approves before file writes.

## Testing Changes

- Verify YAML/Markdown renders correctly
- Confirm adapter pointers match canonical paths
- Run hook scripts: `bash .claude/hooks/session-start.sh`

## License

MIT — see [LICENSE](LICENSE).
