# GitHub Copilot Integration

## Repository Instructions

Create `.github/copilot-instructions.md` in your application repo (or use org-level instructions):

```markdown
# Rolos AI Development Studio

Follow standards in .ai/standards/. Key rules:
- Rails conventions over custom abstractions
- Authorization on every mutating controller action
- Reversible database migrations with indexed foreign keys
- No secrets in code

For reviews, align with .ai/standards/code-review.md severity levels.
```

## Chat

In Copilot Chat, reference canonical paths:

```
Review this model per .ai/skills/review-rails-models/SKILL.md
```

## Limitations

Copilot does not load `.cursor/rules/` or Claude skills automatically. Keep `.ai/standards/` concise for chat context.
