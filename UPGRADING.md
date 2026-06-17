# Upgrading to Rolos AI Development Studio

## From Claude Code Game Studios

If you used the previous **game studio** template, content is preserved in `archive/game-studio-original/`.

### What Changed

| Before | After |
|--------|-------|
| `.claude/` as source of truth | `.ai/` as source of truth |
| 49 game agents | 13 software engineering agents |
| 73 game skills | 15 Rails/AWS skills |
| Game workflows (GDD, playtest) | Software workflows (feature, incident, deploy, OCR) |
| Engine-specific rules | Rails, AWS, MySQL, security rules |

### Migration Steps

1. **Back up** any custom agents/skills you added to the old `.claude/`.
2. **Copy** new `.ai/`, `.cursor/`, `.claude/` from this repo.
3. **Merge** custom content into `.ai/` using the YAML skill/agent format.
4. **Update** your app's `CLAUDE.md` to point to `.ai/`.
5. **Archive** old game-specific docs locally if still needed.

### Safe to Overwrite

- Root `README.md`, `CLAUDE.md`
- `.cursor/rules/`
- Thin `.claude/agents/` and `.claude/skills/`

### Merge Manually

- Custom hooks beyond git validation
- Project-specific standards → add as `.ai/standards/<your-standard>.md`
- Custom templates → `.ai/templates/`

### Restoring Game Studio Content

```bash
ls archive/game-studio-original/
cat archive/game-studio-original/MANIFEST.md
```

Do not restore the full `.claude/` tree — it conflicts with the new adapter model.
