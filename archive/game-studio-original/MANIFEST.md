# Game Studio Original — Archive Manifest

**Archived:** 2026-06-16  
**Reason:** Repository refactored into Rolos AI Development Studio — a vendor-neutral AI engineering framework for Rails/AWS/MySQL/Odoo/Textract workflows.

---

## What Was Moved

| Path | Description |
|------|-------------|
| `.claude/` | Full Claude Code Game Studios framework (49 agents, 73 skills, 12 hooks, 11 rules, 41 templates) |
| `design/` | Game design directory and entity registry |
| `src/` | Game source placeholder |
| `production/` | Sprint/milestone/release tracking (empty except session-state) |
| `CCGS Skill Testing Framework/` | Skill testing framework duplicate (127 files) |
| `docs-engine-reference/` | Godot, Unity, Unreal engine API references (~40 files) |
| `docs-examples/` | Example Claude Code session transcripts for game workflows |
| `docs-architecture/` | GDD traceability registry (`tr-registry.yaml`) |
| `docs-registry/` | Architecture registry for game systems |
| `WORKFLOW-GUIDE.md` | 7-phase game development pipeline guide |
| `README-game-studios.md` | Original README |
| `CLAUDE-game-studios.md` | Original CLAUDE.md |
| `UPGRADING.md` | CCGS upgrade guide |

---

## Why It Was Moved

This content is **game-development-specific**:

- Agents for game design, art, audio, narrative, engine specialists (Godot/Unity/Unreal)
- Skills for GDDs, art bibles, playtesting, vertical slices, balance checks
- Rules scoped to gameplay, shaders, narrative, and engine code paths
- Hooks detecting game engines, GDDs, and asset pipelines
- Templates for game concepts, level design, HUD design, economy models

None of this applies to the Rolos software engineering stack (Rails, React/Inertia, AWS, MySQL, Odoo, Textract).

---

## Possible Future Reuse

| Archived Artifact | Reuse Idea |
|-------------------|------------|
| `workflow-catalog.yaml` | Pattern for declarative YAML workflows in `.ai/workflows/` |
| `team-*` skills | Multi-agent orchestration pattern for complex features |
| `COLLABORATIVE-DESIGN-PRINCIPLE.md` (kept in `docs/`) | User-driven collaboration protocol — already preserved |
| `architecture-decision-record.md` template | Adapted (engine sections removed) in `.ai/templates/` |
| `incident-response.md` / `post-mortem.md` | Adapted for production incident workflow |
| `code-review`, `security-audit`, `qa-plan`, `tech-debt` skills | Structural patterns adapted for Rails/AWS |
| `hooks/` (validate-commit, validate-push) | Git safety hooks — logic adapted in new `.claude/hooks/` |
| `gate-check` skill | Phase-gate pattern for release readiness |
| Engine reference docs | Reference if Rolos ever adds game projects as a separate product line |

---

## Restoration

To inspect archived content:

```bash
ls archive/game-studio-original/
```

To restore a specific file for reference (do not restore wholesale):

```bash
cp archive/game-studio-original/.claude/skills/code-review/SKILL.md /tmp/reference.md
```
