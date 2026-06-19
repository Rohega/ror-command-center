# Rails Frontend Standards (React / Inertia / Tailwind)

> Frontend development standard (Hotwire and React + Inertia). Backend rules live in
> `.ai/standards/development.md`; UX and accessibility rules live in
> `.ai/standards/ux-accessibility.md`.

## Architecture

- Server is the source of truth — no duplicated business logic or validation in React
- Use Inertia visits and Inertia forms; avoid ad-hoc `fetch`/axios unless ADR-approved
- Pages live under the Inertia pages directory; keep shared UI in reusable components
- Props come from Rails serializers — align shapes with the Backend Rails Developer
- Avoid uncontrolled global state for server-owned data

## Component States

- Every data-driven component handles loading, error, and empty states explicitly
- Optimistic UI only when failure handling and rollback are defined

## Styling (Tailwind)

- Use Tailwind utility classes with the project's theme scale — no arbitrary magic values
- Define design tokens in the Tailwind theme config; reuse before adding new ones
- Extract repeated class clusters into components, not copy-pasted markup

## Accessibility

- Follow `.ai/standards/ux-accessibility.md` (WCAG 2.2 AA): keyboard, focus, contrast,
  ARIA, `prefers-reduced-motion`
- Ship no UI without keyboard navigation and focus management

## Testing & Tooling

- Component tests (Jest/Vitest) for critical UI flows
- No console errors in the production build
- Lint/format per project config; no new offenses in changed files

## References

- Agent: `.ai/agents/frontend-react-inertia-developer.yaml`
- UX/Accessibility: `.ai/standards/ux-accessibility.md`
- Backend: `.ai/standards/development.md`
