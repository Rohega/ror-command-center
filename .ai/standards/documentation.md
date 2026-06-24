# Documentation Standards

## What to Document

| Artifact | Location | When |
|----------|----------|------|
| Module overview | `docs/modules/<name>.md` | New feature area |
| ADR | `docs/architecture/adr-NNNN-*.md` | Significant technical decision |
| API | `docs/api/` or OpenAPI | Public or partner APIs |
| Runbook | `docs/runbooks/` | Deploy, incident, integration ops |
| Feature spec | `docs/specs/` | Before implementation |
| User guide / onboarding | `docs/` (README, `docs/USER-MANUAL.md`, runbooks) | Onboarding, install, or any setup/UX change a user follows |

**Audience matters:** developer-facing docs (modules, APIs) use the
`document-module` skill; user-facing docs (install/onboarding, how-tos) use the
`document-user-guide` skill — lead with the user's task, not internals.

## User guide: text vs video demo

User-facing documentation comes in two complementary media. Choose by what the
reader needs, and compose them when a flow deserves both.

| | Text user guide | Video demo |
|---|----------------|------------|
| Skill | `document-user-guide` | `record-user-demo` |
| Best for | Prerequisites, copy-paste steps, troubleshooting, edge cases, anything scannable/searchable | Multi-step or visual flows where "showing" beats "telling" (drag/drop, state changes, full login→action paths) |
| Output | README / `docs/USER-MANUAL.md` / runbooks (Markdown) | `public/video/<feature>.webm` + `.vtt` captions, embedded in the in-app manual |
| Accessibility | Native text | **Captions required** (`.vtt`) — narration is by synchronized subtitles, not audio |

- **Default to text.** It is cheaper, searchable, and translatable. Reach for a
  video demo only when a flow is genuinely hard to describe in prose.
- **Compose them.** Embed the demo inside the text guide with Markdown image
  syntax — `![Demo: <feature>](video/<feature>.webm)` — so one page carries both.
- Video demos drive the *real* app with Playwright and may create real records
  in **development** data; never run them against production. See the
  `record-user-demo` skill for the full toolchain, prerequisites, and the
  minimalism rationale (Playwright-native `.webm` over screenshots+ffmpeg).

## Style

- Clear headings, short paragraphs
- Code examples tested or marked `# illustrative`
- Link to ADRs instead of duplicating rationale
- Date and author on runbooks

## Language Convention

English is the canonical language. When a document also needs a Spanish
version, keep both in the **same file** (do not rename files — this avoids
breaking cross-references) using this layout:

```markdown
> Language: English | [Español](#versión-en-español)

# Title (English)

...canonical English content...

---

## Versión en español

...original Spanish content, kept intact...
```

- English first (canonical), Spanish below under a stable anchor.
- New documents should be written in English; add the Spanish block only when
  the audience needs it.
- Code blocks, commands, and file paths are shared — do not translate them.

## Maintenance

- Update docs in same PR as code when behavior changes
- Quarterly review of runbooks for accuracy

## References

- Agent: `.ai/agents/documentation-writer.yaml`
- Skills: `document-module` (developer-facing), `document-user-guide` (user-facing text), `record-user-demo` (user-facing video)
- Templates: `.ai/templates/technical-design-document.md`, `.ai/templates/user-guide.md`, `.ai/templates/user-demo-script.md`
