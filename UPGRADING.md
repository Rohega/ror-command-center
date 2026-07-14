# Upgrading to RoR Command Center

## From Claude Code Game Studios

If you used the previous **game studio** template, content is preserved in `archive/game-studio-original/`.

### What Changed

| Before | After |
|--------|-------|
| `.claude/` as source of truth | `.ai/` as source of truth |
| 49 game agents | 8 Rails specialists |
| 73 game skills | 24 Rails/AWS skills |
| Engine / game standards | 21 Rails, AWS, data, security, and process standards |
| Game workflows (GDD, playtest) | Software workflows (feature, incident, deploy, legacy onboarding) |
| Engine-specific rules | Rails, AWS, MySQL/PostgreSQL, security rules |

Counts above match this repo’s `.ai/skills/` and `.ai/standards/` directories at publish time — list those dirs if you need an exact inventory.

### Migration Steps

1. **Back up** any custom agents/skills you added to the old `.claude/`.
2. **Copy** new `.ai/`, `.cursor/`, `.claude/` from this repo (or re-run `./install.sh --force --backup` on your app).
3. **Merge** custom content into `.ai/` using the YAML skill/agent format.
4. **Update** your app’s `CLAUDE.md` / `AGENTS.md` to point to `.ai/`.
5. **Archive** old game-specific docs locally if still needed.

### Safe to Overwrite

- Root `README.md`, `CLAUDE.md`, `AGENTS.md`
- `.cursor/rules/`
- Thin `.claude/agents/` and `.claude/skills/`

### Merge Manually

- Custom hooks beyond git validation
- Project-specific standards → add as `.ai/standards/<your-standard>.md`
- Custom templates → `.ai/templates/`

### Restoring Game Studio Content

```bash
ls archive/game-studio-original/
```
