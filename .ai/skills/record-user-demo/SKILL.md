---
name: record-user-demo
description: "Generate an accessible video demo per feature by driving the real app with Playwright (login + flow), exporting native .webm plus a .vtt caption track, and embedding it in an in-app user manual. Use when a user-facing feature needs a guided video walkthrough alongside text docs."
---
# record-user-demo

## Purpose

Generate an accessible **video demo per feature** that drives the *real*
application with Playwright (login + flow), and embed it in an in-app user
manual. Each run produces a Playwright-native `.webm` (no ffmpeg) plus a `.vtt`
subtitle track per step — narration is delivered via synchronized captions, not
audio. The result is a reproducible, vendor-neutral toolchain so every RoRCC
project can ship video user guides without reinventing the recorder.

**Use when:** a user-facing feature benefits from a guided walkthrough that text
alone cannot convey (multi-step flows, drag/drop, visual state changes), or when
producing the video half of a user guide (`document-user-guide` covers the text
half).

This is the **video** counterpart to `document-user-guide` (text) — see the
distinction table at the end.

## Inputs

- A running instance of the app (dev server reachable at a configurable
  `BASE_URL`, e.g. `http://localhost:3000`).
- A seeded **demo user** whose credentials come from the environment
  (`<APP>_DEMO_EMAIL` / `<APP>_DEMO_PASSWORD`), never hardcoded.
- Playwright installed with the Chromium browser (see Prerequisites).
- The feature flow to demonstrate (steps, selectors, narration text).
- Standards: `.ai/standards/documentation.md`, `.ai/standards/minimalism.md`,
  `.ai/standards/security.md`.
- Template: `.ai/templates/user-demo-script.md` (scaffold for `_helpers.mjs`,
  `<feature>.mjs`, the credential-alignment script, and the embed component).

## Outputs

- `script/demos/_helpers.mjs` — shared recorder (`recordDemo`) created once per
  repo.
- `script/demos/<feature>.mjs` — one script per feature.
- `public/video/<feature>.webm` + `public/video/<feature>.vtt` — the rendered
  demo and its captions, served statically.
- An embed in the in-app manual (e.g. `/help`, `/ayuda`) using Markdown image
  syntax: `![Demo: <feature>](video/<feature>.webm)`.
- (If the embed component is new) a Markdown renderer that emits `<video>` for
  `.mp4/.webm` and `<img>` otherwise, plus its JS test.

## Prerequisites

1. **App + seed.** The app runs at `BASE_URL` and a demo user exists. Provide an
   idempotent **credential-alignment script** (e.g.
   `script/demos/align_demo_password.rb`) that syncs the demo user's password in
   the DB to `<APP>_DEMO_PASSWORD`, run via `bin/rails runner`. This guarantees
   the recorder can always log in regardless of seed drift.
2. **Playwright.** Add `@playwright/test` (or `playwright`) as a **devDependency**
   and install the browser:
   - Local: `npx playwright install chromium`
   - **Docker (persistent).** Install the browser *in the image* so it survives
     container rebuilds and is not re-downloaded per run. Either base the build
     stage on the official image (`mcr.microsoft.com/playwright:vX.Y.Z-jammy`,
     which ships browsers + OS deps) **or** add to your `Dockerfile`:

     ```dockerfile
     # ponytail: official Playwright image if you don't already manage a Node layer
     RUN npx playwright install --with-deps chromium
     ```

     Pin the Playwright version so the installed browser matches the library.
3. **Credentials by environment.** Document every variable in `.env.example`
   (`<APP>_DEMO_EMAIL`, `<APP>_DEMO_PASSWORD`, optional `BASE_URL`,
   `DEMO_LOCALE`). Never commit real credentials; never hardcode them in scripts.

> **Data warning.** Each run drives the *real* app and may create real records
> in the **development** database. Point demos at development/staging only —
> **never production**.

## Execution Steps

1. **Scaffold the shared helper (once).** Copy `_helpers.mjs` from the template.
   It launches headless `chromium` with `recordVideo`, a `1280x720` viewport and
   a configurable `locale`; injects a **fake cursor** via `addInitScript`
   (Playwright does not draw the pointer in the recording); exposes a controller
   `d` with `goto/fill/select/click` (each moves the real cursor with
   `page.mouse.move(..., { steps })`) and `narrate(text, holdMs)` accumulating
   cues `{ startMs, endMs, text }`. On `context.close()` the `.webm` is
   materialized, renamed to `<name>.webm`, and a `<name>.vtt` is written via
   `formatVtt(cues)` (`HH:MM:SS.mmm` timestamps).
2. **Write the feature script.** Create `script/demos/<feature>.mjs` calling
   `recordDemo({ name, baseURL, outDir, slowMo, run })`. In `run`, read the demo
   credentials from `process.env`, log in, then alternate `d.narrate(...)` with
   actions to walk the flow. Keep narration short and synchronized to each step.
3. **Align credentials.** Run the alignment script so the demo user's password
   matches the env var:
   `bin/rails runner script/demos/align_demo_password.rb`.
4. **Generate the demo.** Start the app, then run the script, e.g.
   `BASE_URL=http://localhost:3000 node script/demos/<feature>.mjs`. Confirm
   `public/video/<feature>.webm` and `.vtt` are produced.
5. **Embed it.** In the manual page, reference the video with Markdown image
   syntax: `![Demo: <feature>](video/<feature>.webm)`. The renderer detects the
   `.mp4/.webm` extension and emits `<video controls preload="metadata">` with a
   `<track kind="captions" srclang default>` whose `src` is the same base name
   `.vtt` (resolved by convention); otherwise it emits `<img>`. `urlTransform`
   rewrites relative paths to `/public`.
6. **Serve statically.** Rails/Puma serves `public/` with `video/webm` and
   `text/vtt`, honoring range requests so the user can seek/fast-forward. No
   extra route needed.
7. **Validate (see checklist).** Add/confirm the embed-component JS test and do a
   visual check in the browser.

## Validation Checklist

- [ ] `public/video/<feature>.webm` and matching `.vtt` exist and the base names
      align (caption resolution is by convention).
- [ ] **Embed-component JS test** (when the renderer is new/changed): a `.webm`/
      `.mp4` `src` renders `<video>` + `<track ... default>`; any other `src`
      renders `<img>`.
- [ ] **Visual verification in the browser** on the help page: the video plays
      (`video.readyState` high, e.g. ≥ 2/`HAVE_CURRENT_DATA`) and the caption
      track is loaded (a `textTrack` with `cues.length > 0`, `mode` showing).
- [ ] Credentials read from environment only; `.env.example` documents every var.
- [ ] No real credentials in scripts or committed video metadata.
- [ ] Run targeted dev/staging, not production; data-creation side effects noted.
- [ ] Playwright version pinned and the Chromium install persists in Docker.

## Minimalism decision (explicit exception to `minimalism.md`)

The ladder in `.ai/standards/minimalism.md` favors the fewest dependencies.
Here we **deliberately add Playwright** rather than hand-rolling capture:

- **Chosen:** Playwright headless Chromium with native `.webm` `recordVideo`.
  One devDependency yields video without an encoding pipeline, and a fake-cursor
  init script covers the only gap (pointer rendering).
- **Austere alternative (the ceiling):** scripted screenshots stitched with
  `ffmpeg`. This avoids the browser-automation dependency but is *more* fragile
  and *more* code (frame timing, encoding flags, an extra system binary) for a
  **recurring** need across projects — so it loses on the "less fragile code"
  criterion the ladder optimizes for.
- The helper marks this with `# ponytail: Playwright-native webm; downgrade to
  screenshots+ffmpeg only if a browserless CI forbids Chromium`.
- **Do not** add ffmpeg or format conversion unless a real need appears (e.g.
  legacy Safari that cannot play `.webm` → transcode to `.mp4`).

## Distinction from `document-user-guide`

| | `record-user-demo` | `document-user-guide` |
|---|--------------------|------------------------|
| Medium | Video (`.webm` + `.vtt` captions) | Text (Markdown) |
| Answers | "Show me how X looks/flows" | "How do I do X (steps/troubleshooting)?" |
| Best for | Multi-step, visual, hard-to-describe flows | Prerequisites, copy-paste commands, edge cases |
| Output | `public/video/<feature>.{webm,vtt}` + embed | README / `docs/USER-MANUAL.md` / runbooks |

They compose: embed the demo *inside* the text guide for the richest result.

## Agent

`documentation-writer` — see `.ai/agents/documentation-writer.yaml`.
For the embed component + test, pair with `frontend-react-inertia-developer`.

## Workflow

`.ai/workflows/new-feature.yaml` → phase `documentation`.
