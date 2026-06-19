# UX & Accessibility Standards

> Principles for usable, accessible interfaces. Rails-specific UI tooling
> (Hotwire, React + Inertia, Tailwind) lives in `.ai/standards/frontend.md`.

## Accessibility (WCAG 2.2 AA — minimum bar)

- Color contrast >= 4.5:1 for body text, >= 3:1 for large text and UI components
- Fully keyboard operable with a logical, predictable tab order
- Visible focus indicators on every interactive element
- Manage focus for modals, drawers, and dynamically revealed content
- Semantic HTML first; add ARIA roles/labels only when semantics are insufficient
- Form fields have associated labels and programmatically linked error messaging
- Respect `prefers-reduced-motion` — provide non-animated fallbacks
- Touch targets >= 44x44px
- Content reflows without horizontal scroll down to 320px width

## Required UI States

Every screen and data-driven component must specify all four states:

- **Loading** — skeletons or spinners, never a blank frozen view
- **Empty** — explain the absence and offer a next action
- **Error** — human-readable message plus a recovery path
- **Success** — confirm the result of the user's action

## Layout & Responsiveness

- Mobile-first: design the smallest target first, enhance upward
- Define behavior per breakpoint; avoid content that only works on one viewport
- Maintain a clear visual hierarchy and consistent spacing rhythm

## Design Tokens

- Reuse existing design-system tokens (color, typography, spacing, radius, elevation)
  before introducing new values
- No arbitrary one-off magic numbers when a token exists
- New tokens are proposed in the UX spec, not invented ad hoc in code

## Content & UX Writing

- Labels, errors, and empty states use plain, action-oriented language
- Be consistent with terminology across the product

## References

- Agent: `.ai/agents/frontend-react-inertia-developer.yaml` (UX/accessibility responsibilities)
- Skill: `create-ux-spec`
- Template: `.ai/templates/ux-specification.md`
