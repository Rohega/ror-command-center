---
name: document-user-guide
description: "Create or update user-facing documentation for a non-technical, task-oriented audience: install/onboarding guides, human READMEs, runbooks, and how-to walkthroughs. Use when the reader asks 'how do I do X?' rather than 'how is this built?'."
---
# document-user-guide

## Purpose

Create or update **user-facing** documentation for a non-technical or
task-oriented audience: install/onboarding guides, READMEs for humans, runbooks,
and how-to walkthroughs. This is the user counterpart to `document-module`
(which targets developers and code internals).

Use this skill when the reader asks *"how do I do X?"* rather than *"how is this
built?"*.

## Inputs

- The task or product the user needs to accomplish (e.g. "install locally",
  "start a new project with Docker")
- The actual behavior to document — scripts, commands, CLI help, screenshots
- Standard: `.ai/standards/documentation.md`
- Template: `.ai/templates/user-guide.md`

## Outputs

- A user guide or section under `docs/` (README, `docs/USER-MANUAL.md`,
  `docs/runbooks/<name>.md`, or a how-to), in the audience's language

## Execution Steps

1. **Define the audience** — Who reads this and what is their technical level?
   State assumed prior knowledge explicitly. Non-technical readers get zero
   unexplained jargon.
2. **Frame the goal as a task** — Lead with what the user wants to achieve and
   the end state, not with internal architecture.
3. **List prerequisites** — Exactly what must be installed/ready before step 1.
   Separate hard requirements from optional choices (e.g. "needs Docker; Ollama
   is optional").
4. **Write copy-paste steps** — Numbered, ordered, each a runnable command or a
   concrete action. Verify every command against the real script/CLI.
5. **Add verification + troubleshooting** — How the user confirms success, and a
   table of common symptoms → fixes.
6. **Cut jargon / add a glossary** — Replace or define every technical term a
   target reader would not know.
7. **Cross-check** — Steps match current behavior (`setup.sh`, `install.sh`,
   `rorcc`, etc.). Fix stale commands.
8. **Approve** — Show the draft and wait for sign-off before writing final files.
9. **Link** — Add the guide to the relevant index (README, `docs/USER-MANUAL.md`
   references, runbook list).

## Validation Checklist

- [ ] Audience and assumed knowledge stated
- [ ] Goal framed as a user task, not internals
- [ ] Hard prerequisites separated from optional choices
- [ ] Every command verified against current scripts/CLI
- [ ] Verification step and troubleshooting table present
- [ ] No unexplained jargon (or glossary provided)
- [ ] Linked from the relevant index
- [ ] Date-stamped if it is a runbook

## Distinction from `document-module`

| | `document-user-guide` | `document-module` |
|---|----------------------|-------------------|
| Reader | End user / non-technical | Developer |
| Answers | "How do I do X?" | "How is this built / what is its interface?" |
| Output | README, manual, runbooks, how-tos | `docs/modules/<name>.md` |

## Agent

`documentation-writer` — see `.ai/agents/documentation-writer.yaml`
