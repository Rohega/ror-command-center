# Cursor Integration

How to use RoR Command Center inside Cursor — from your first prompt to advanced workflows.

## Concepts in 30 seconds

| Term | Where it lives | In plain words |
|------|----------------|----------------|
| **Rule** | `.cursor/rules/` | Instructions Cursor loads on its own — you don't ask for them. |
| **Standard** | `.ai/standards/` | The source of truth for "how we build things". Rules point here. |
| **Skill** | `.ai/skills/` (+ `.claude/skills/` adapter) | A single concrete task (e.g. "draft a feature spec"). |
| **Agent (role)** | `.ai/agents/<id>.yaml` | Canonical specialist definition (`id` + `delegation`). |
| **Subagent** | `.cursor/agents/<id>.md` | Native Cursor specialist Cursor can Task-delegate to. |
| **Workflow** | `.ai/workflows/` | Several steps chained together (e.g. feature from idea to deploy). |

## Quickstart (5 minutes)

1. Open the project in Cursor. Rules in `.cursor/rules/` load automatically.
2. Open Agent chat and paste:

   > /backend-rails-developer I want to add a "phone" field to the User model,
   > following .ai/standards/development.md. Ask me questions first — don't edit yet.

3. What to expect: the subagent reads `.ai/agents/backend-rails-developer.yaml`,
   asks 2–3 questions (validation? index? nullable?), proposes a plan, and waits
   for your approval before writing any code.
4. Reply, approve, and let it implement. You stay in control at every step.

## Ask mode vs Agent mode

Cursor has two chat modes — picking the right one avoids most confusion:

| Mode | What it does | Use it for |
|------|--------------|------------|
| **Ask** | Reads and answers. **Never edits files.** | Planning, reviews, "how does X work?" |
| **Agent** | Can create and edit files, run commands, spawn subagents. | Implementing the approved plan. |

Tip: plan in **Ask**, then switch to **Agent** to implement. Subagent `/<id>`
works best in Agent mode (Task tool).

## Rules Map

All rules reference a canonical standard in `.ai/` — they never duplicate it.

| Cursor Rule | Canonical Standard |
|-------------|-------------------|
| `ai-index.mdc` | `.ai/` router — loads the core standards every chat and routes agents/skills/workflows/domain standards |
| `project-structure.mdc` | `.ai/` layout |
| `workflow-gates.mdc` | `.ai/workflows/new-feature.yaml`, `.ai/standards/project-bootstrap.md` |
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

**Why some rules always apply and others don't:**
`ai-index.mdc`, `project-structure.mdc`, `minimalism.mdc`, and
`workflow-gates.mdc` are `alwaysApply: true`, so they load in every chat.
`ai-index.mdc` is the **router**: it `@`-loads the 9 core standards (collaboration,
minimalism, development, project-bootstrap, testing, security, git-workflow,
code-review, documentation) and lists every agent, skill, workflow, and domain
standard so the agent always considers `.ai/` — even on greenfield projects or
non-Ruby work where no glob matches. `workflow-gates.mdc` keeps the Definition of
Done in scope. The domain rules activate by file glob (e.g. `rails.mdc` activates
when you touch `app/**/*.rb`). You can also force any rule by `@`-mentioning its file.

**Hard gates (`.cursor/hooks.json`):** beyond advisory rules, Cursor hooks
deterministically block direct pushes to `main`/`master`/`develop`, flag staged
secrets before commits, and surface bootstrap gaps (missing RSpec) at session
start. See **Settings > Hooks** to inspect them.

## Copy-paste recipes

### 1. Draft a feature spec (subagent + skill)

```
/product-owner Follow .ai/skills/create-feature-spec/SKILL.md to draft a spec
for "multi-warehouse stock transfer". Ask me questions first, then save it to
docs/specs/stock-transfer.md.
```

### 2. Review a model against the standards (subagent + standard)

```
/qa-engineer Review app/models/invoice.rb against .ai/standards/development.md
and .ai/standards/security.md. List issues by severity; do not edit files yet.
```

### 3. Run the full new-feature workflow (workflow)

```
Execute .ai/workflows/new-feature.yaml for "multi-warehouse stock transfer".
Stop after each phase and wait for my approval before continuing. Delegate each
phase to the matching Cursor subagent.
```

### 4. Architecture decision (subagent + template)

```
/rails-architect Using the template
.ai/templates/architecture-decision-record.md, propose an ADR for choosing
between Sidekiq and Solid Queue. Save it to docs/architecture/adr-0001-job-backend.md.
```

### 5. Make the agent always honor the framework (project rule)

The always-applied rule `.cursor/rules/project-structure.mdc` already tells the
agent that `.ai/` is the single source of truth. Reinforce it per-chat with:

```
For this project, treat .ai/ as the source of truth. Before implementing,
delegate to the matching subagent in .cursor/agents/ (which reads .ai/agents/),
load the skill from .ai/skills/, and the standards from .ai/standards/. Follow
the collaboration protocol: ask, present options, draft, and wait for my
approval before writing files.
```

> Tip: use Cursor's `@`-mentions to attach the exact file, e.g.
> `@.ai/skills/create-feature-spec/SKILL.md`, so the agent reads it directly.
> Fallback without Task: `Act as the agent in .ai/agents/<id>.yaml …`.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Agent ignores the standards | Rule didn't activate (wrong file type) | `@`-mention the standard or rule file directly. |
| Subagent not used | Vague prompt / Ask mode | Use `/<id>` or “use the `<id>` subagent”; switch to Agent mode. |
| "Where do I type prompts?" | — | Open the chat with Cmd/Ctrl + L. |
| Agent edits without asking | You're in Agent mode and didn't ask it to confirm | Add "ask before editing" to your prompt, or use Ask mode to plan. |
| Not sure which rules are active | Rules activate by file glob | Open a file of that type, or `@`-mention the rule. |
| Agent doesn't follow the team process | Collaboration protocol not reinforced | Use recipe #5 above. |

## Customization

Add project-specific rules in `.cursor/rules/` that **reference** `.ai/standards/` — do not copy standard text into Cursor rules.
New specialists: add `.ai/agents/<id>.yaml` with `delegation`, then a thin
`.cursor/agents/<id>.md` adapter (see [create-specialist-agent.md](../how-to/create-specialist-agent.md)).
