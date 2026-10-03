# Native Agent Orchestration

RoR Command Center keeps one vendor-neutral decision layer and lets each coding
agent use its own native runtime.

```text
request
  ↓
RORCC Task Router
(size + risk signals + applies_when + path routing)
  ↓
selected work only
  ↓
native runtime
(Cursor / Claude Code / Codex)
  ↓
lead + explorer + selected specialists + earned review
```

The key rule is simple: **RORCC decides what should happen; the runtime decides
how to distribute that selected work.**

Canonical policy: `.ai/standards/native-agent-orchestration.md`.

## What changes by platform

| Platform | Discovery | Specialist execution | Parallel work |
|----------|-----------|----------------------|---------------|
| Cursor | Prefer built-in repository exploration | `.cursor/agents/<id>.md` | Native subagents when independent |
| Claude Code | Prefer built-in Explore/Plan | `.claude/agents/<id>.md` | Subagents; agent teams only when peers must communicate |
| Codex | Use repo exploration in the Codex harness | Roles from `.ai/agents/` under `AGENTS.md` policy | Harness multi-agent delegation when available |

RORCC intentionally does **not** create its own generic Explorer/Researcher if
the runtime already has one. That would duplicate platform capabilities and
increase context/token usage.

## Checkpoints that justify a stronger reviewer

Escalate architecture/review when one of these is true:

1. XL or `architecture_changed` before implementation.
2. The same implementation/debugging failure has happened twice.
3. L/XL or high-risk work is about to close and no equivalent independent
   RORCC review has already run.

For S/M work, stay with the lead agent unless a risk signal earns a specialist.

## Example

For “change Login to Entrar”, the router classifies S. The lead edits/verifies
the copy; no Product Owner, Architect, QA team, or docs agent is created.

For “migrate Sidekiq to Solid Queue”, the router classifies XL with architecture
impact. The runtime may use native exploration, invoke the Rails Architect before
implementation, split independent implementation work if useful, and run one
independent completion review.

That behavior is the same policy across platforms even though each runtime uses
different native primitives.
