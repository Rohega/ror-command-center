# User Demo Script — scaffold

> **Illustrative**, not drop-in. Generalize names/paths/selectors to your app.
> Used by the `record-user-demo` skill (`.ai/skills/record-user-demo/SKILL.md`).
> Credentials come from the environment — never hardcode them. Each run drives
> the real app and may create records in **development** data; never production.

## 1. Shared recorder — `script/demos/_helpers.mjs`

Create once per repo. Launches Chromium, records native `.webm`, injects a fake
cursor (Playwright doesn't draw the pointer), and writes a `.vtt` caption track.

```javascript
// script/demos/_helpers.mjs  # illustrative
import { chromium } from "playwright";
import { rename, writeFile } from "node:fs/promises";
import { join } from "node:path";

// ponytail: Playwright-native webm; downgrade to screenshots+ffmpeg only if a
// browserless CI forbids Chromium. ffmpeg is more code and more fragile for a
// recurring, cross-project need.

const pad = (n, w = 2) => String(n).padStart(w, "0");
const ts = (ms) => {
  const h = Math.floor(ms / 3600000);
  const m = Math.floor((ms % 3600000) / 60000);
  const s = Math.floor((ms % 60000) / 1000);
  return `${pad(h)}:${pad(m)}:${pad(s)}.${pad(ms % 1000, 3)}`;
};

function formatVtt(cues) {
  return (
    "WEBVTT\n\n" +
    cues
      .map((c, i) => `${i + 1}\n${ts(c.startMs)} --> ${ts(c.endMs)}\n${c.text}\n`)
      .join("\n")
  );
}

export async function recordDemo({ name, baseURL, outDir, slowMo = 250, run }) {
  const browser = await chromium.launch({ headless: true, slowMo });
  const context = await browser.newContext({
    viewport: { width: 1280, height: 720 },
    locale: process.env.DEMO_LOCALE || "en-US",
    recordVideo: { dir: outDir, size: { width: 1280, height: 720 } },
    baseURL,
  });

  // Fake cursor: Playwright does not render the real pointer in the video.
  await context.addInitScript(() => {
    const dot = document.createElement("div");
    dot.style.cssText =
      "position:fixed;z-index:99999;width:16px;height:16px;margin:-8px 0 0 -8px;" +
      "border-radius:50%;background:rgba(0,0,0,.55);pointer-events:none;transition:all .08s";
    addEventListener("DOMContentLoaded", () => document.body.appendChild(dot));
    addEventListener("mousemove", (e) => {
      dot.style.left = e.clientX + "px";
      dot.style.top = e.clientY + "px";
    });
  });

  const page = await context.newPage();
  const cues = [];
  let clock = 0;

  const moveTo = async (locator) => {
    const box = await locator.boundingBox();
    if (box) {
      await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2, {
        steps: 20,
      });
    }
  };

  const d = {
    page,
    async goto(path) {
      await page.goto(path);
    },
    async fill(selector, value) {
      const el = page.locator(selector);
      await moveTo(el);
      await el.fill(value);
    },
    async select(selector, value) {
      const el = page.locator(selector);
      await moveTo(el);
      await el.selectOption(value);
    },
    async click(selector) {
      const el = page.locator(selector);
      await moveTo(el);
      await el.click();
    },
    async narrate(text, holdMs = 2500) {
      cues.push({ startMs: clock, endMs: clock + holdMs, text });
      clock += holdMs;
      await page.waitForTimeout(holdMs);
    },
  };

  try {
    await run(d);
  } finally {
    await context.close(); // materializes the .webm
    await browser.close();
  }

  const video = await page.video();
  const tmp = await video.path();
  await rename(tmp, join(outDir, `${name}.webm`));
  await writeFile(join(outDir, `${name}.vtt`), formatVtt(cues), "utf8");
}
```

## 2. One script per feature — `script/demos/<feature>.mjs`

```javascript
// script/demos/<feature>.mjs  # illustrative
import { recordDemo } from "./_helpers.mjs";

const baseURL = process.env.BASE_URL || "http://localhost:3000";
const email = process.env.APP_DEMO_EMAIL;     // from env, never hardcoded
const password = process.env.APP_DEMO_PASSWORD;

await recordDemo({
  name: "<feature>",
  baseURL,
  outDir: "public/video",
  run: async (d) => {
    await d.narrate("First, we sign in.");
    await d.goto("/login");
    await d.fill("#email", email);
    await d.fill("#password", password);
    await d.click("button[type=submit]");

    await d.narrate("Open the <feature> section.");
    await d.goto("/<feature>");

    await d.narrate("Fill the form and save.");
    await d.fill("#name", "Demo item");
    await d.click("button:has-text('Save')");

    await d.narrate("Done — the new item appears in the list.");
  },
});
```

## 3. Credential alignment — `script/demos/align_demo_password.rb`

Idempotent: syncs the demo user's password in the DB to the env var so the
recorder can always log in. Run with `bin/rails runner`.

```ruby
# script/demos/align_demo_password.rb  # illustrative
email = ENV.fetch("APP_DEMO_EMAIL")
password = ENV.fetch("APP_DEMO_PASSWORD")

user = User.find_or_initialize_by(email: email)
user.password = password
user.password_confirmation = password
user.save!(validate: false) if user.changed?
puts "Aligned demo password for #{email}"
```

```bash
bin/rails runner script/demos/align_demo_password.rb
BASE_URL=http://localhost:3000 node script/demos/<feature>.mjs
```

## 4. Embed component (Markdown image → video|img)

Reuse the Markdown image syntax. If `src` ends in `.mp4`/`.webm`, render a
`<video>` with a captions `<track>` (the `.vtt` is resolved by convention from
the same base name); otherwise render `<img>`. `urlTransform` rewrites relative
paths to `/public`.

```jsx
// MarkdownMedia.jsx  # illustrative (React + react-markdown)
const VIDEO = /\.(mp4|webm)$/i;

const toPublic = (src) => (src?.startsWith("http") ? src : `/${src}`);

export const mediaComponents = {
  img({ src, alt }) {
    const url = toPublic(src);
    if (VIDEO.test(url)) {
      const vtt = url.replace(VIDEO, ".vtt");
      return (
        <video controls preload="metadata" width="100%">
          <source src={url} />
          <track kind="captions" src={vtt} srcLang="en" label="Captions" default />
        </video>
      );
    }
    return <img src={url} alt={alt} loading="lazy" />;
  },
};

// urlTransform={(url) => url}  // keep relative paths; toPublic handles /public
```

```javascript
// MarkdownMedia.test.jsx  # illustrative — gate: video+track vs img
import { render } from "@testing-library/react";
import { mediaComponents } from "./MarkdownMedia";

test("webm src renders <video> with a default captions track", () => {
  const { container } = render(
    mediaComponents.img({ src: "video/demo.webm", alt: "Demo" })
  );
  const video = container.querySelector("video");
  const track = container.querySelector("track[kind=captions][default]");
  expect(video).toBeTruthy();
  expect(track.getAttribute("src")).toBe("/video/demo.vtt");
});

test("image src renders <img>", () => {
  const { container } = render(
    mediaComponents.img({ src: "img/screenshot.png", alt: "Shot" })
  );
  expect(container.querySelector("img")).toBeTruthy();
  expect(container.querySelector("video")).toBeNull();
});
```

## 5. Markdown embed in the manual

```markdown
![Demo: <feature>](video/<feature>.webm)
```

Rails/Puma serves `public/` with `video/webm` + `text/vtt` and honors range
requests, so users can seek/fast-forward.

## 6. Docker — make Chromium persist

Install the browser in the image so it is not re-downloaded per run (pin the
Playwright version to match the library):

```dockerfile
# ponytail: use mcr.microsoft.com/playwright:<ver>-jammy if you don't manage a Node layer
RUN npx playwright install --with-deps chromium
```

## 7. Environment — document in `.env.example`

```bash
APP_DEMO_EMAIL=demo@example.com
APP_DEMO_PASSWORD=change-me-locally
BASE_URL=http://localhost:3000
DEMO_LOCALE=en-US
```
