# create-ux-spec

## Purpose

Guide collaborative authoring of a UX specification from approved user stories to an implementable design ready for frontend development, covering flows, states, design tokens, and accessibility.

**Use when:** designing UI/UX before frontend work or writing a UX spec.

## Inputs

- Approved feature specification and user stories with acceptance criteria
- Existing design system, shared components, and UI conventions
- Target devices, breakpoints, and platform constraints
- Template: `.ai/templates/ux-specification.md`

## Outputs

- `docs/design/ux-[slug].md` (approved UX specification)

## Execution Steps

1. **Clarify** — Confirm target users, devices/breakpoints, and reusable design system assets.
2. **Map flows** — Draft user flows/journeys per story; present for approval.
3. **Wireframe** — Outline layout and visual hierarchy (text/ASCII/Mermaid acceptable).
4. **Specify states** — Define loading, error, empty, and success states for every screen/component.
5. **Define tokens** — Propose design tokens (color, typography, spacing, radius, elevation), reusing the design system first.
6. **Accessibility pass** — Verify WCAG 2.2 AA: contrast, keyboard navigation, focus management, ARIA, prefers-reduced-motion.
7. **Write UX criteria** — Produce testable UX acceptance criteria and an accessibility checklist for the developer.
8. **Approve** — Show draft for review and obtain sign-off before marking Approved.

## Validation Checklist

- [ ] Every user story has a mapped flow and screen design
- [ ] All UI states (loading, error, empty, success) are specified
- [ ] Design tokens defined and reuse the existing design system
- [ ] Responsive behavior defined (mobile-first, breakpoints)
- [ ] WCAG 2.2 AA accessibility checklist completed
- [ ] UX acceptance criteria are testable by QA
- [ ] Open questions tracked with owners
- [ ] Approval recorded

## Agent

`frontend-engineer` — see `.ai/agents/frontend-react-inertia-developer.yaml` (owns UX and accessibility)

## Workflow

`.ai/workflows/new-feature.yaml` → phase `design`
