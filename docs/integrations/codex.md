# OpenAI Codex Integration

Modern Codex auto-loads `AGENTS.md` from the project root, which now carries the
`.ai/` router (core standards + domain routing). For deeper context, load the
relevant `.ai/` files explicitly at session start.

## Minimum Context

`AGENTS.md` loads automatically and points to the team. When you need the full
behavior, paste or attach:

**Core standards (the team — always relevant):**

1. `.ai/standards/collaboration.md`
2. `.ai/standards/minimalism.md`
3. `.ai/standards/development.md`
4. `.ai/standards/project-bootstrap.md`
5. `.ai/standards/testing.md`
6. `.ai/standards/security.md`
7. `.ai/standards/git-workflow.md`
8. `.ai/standards/code-review.md`
9. `.ai/standards/documentation.md`
10. `.ai/standards/native-agent-orchestration.md`

**Plus, for the task at hand:**

- The domain standard for the area you touch (e.g. `.ai/standards/api-design.md`)
- The agent YAML: `.ai/agents/<role>.yaml`
- The skill: `.ai/skills/<skill>/SKILL.md`

Full navigable index: `.ai/README.md`.

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

## Native multi-agent delegation

RORCC uses `AGENTS.md` as the Codex project adapter and **does not require a
project-local `.codex/agents/` layer**. This avoids depending on an
undocumented/project-specific format and keeps `.ai/` canonical.

When the active Codex runtime exposes multi-agent/subagent delegation:

- keep one lead agent responsible for integration and the final response;
- prefer native repository exploration for broad/unfamiliar code;
- delegate only specialist work already earned by the RORCC Task Router;
- escalate architecture/review only at the checkpoints in
  `.ai/standards/native-agent-orchestration.md`;
- do not create a duplicate Explorer, Researcher, or Reviewer when the harness
  or selected RORCC phase already provides that capability.

The Codex harness can evolve independently; the contract RORCC depends on is
`AGENTS.md` + the canonical `.ai/` policy, not a vendor-specific agent roster.

## Workflows

Phase **ids** (not labels) for `new-feature`: `idea`, `specification`,
`architecture`, `implementation-plan`, `development`, `testing`,
`documentation`, `deployment`.

```
Follow .ai/workflows/new-feature.yaml from phase testing.
Stop after each phase and wait for my approval.
```

CLI preview (0 tokens): `rorcc workflow new-feature --plan`.
How-to: [../how-to/run-workflows.md](../how-to/run-workflows.md).

## CI / Automation

In CI pipelines, pass `.ai/skills/<name>/SKILL.md` as system context for automated review steps.
