# Hotwire Standards (Turbo + Stimulus)

> Server-driven frontend standard for Rails using Turbo and Stimulus. For SPA-style
> screens use React + Inertia (`.ai/standards/frontend.md`). Choose one approach per
> screen via ADR — do not mix on the same view without justification.

## When to Use Hotwire vs React/Inertia

- **Hotwire**: CRUD, forms, dashboards, mostly server-rendered apps with light interactivity
- **React/Inertia**: complex client state, rich interactions, highly dynamic UIs

## Turbo

- **Turbo Drive**: keep navigation server-driven; avoid full-page JS frameworks fighting it
- **Turbo Frames**: scope partial updates; give frames stable `id`s
- **Turbo Streams**: server-pushed updates over WebSocket (Action Cable) or HTTP responses
- Broadcast streams from models/jobs deliberately; authorize stream subscriptions per user
- Keep stream payloads small; render partials, not whole pages

## Stimulus

- One controller per behavior; keep them small and reusable
- Use `data-*` actions/targets/values — no inline JS, no manual DOM querying by class
- No business logic in controllers; the server remains the source of truth
- Clean up listeners/timers in `disconnect()`

## Accessibility & States

- Preserve focus across Turbo Frame/Stream updates
- Handle loading, error, and empty states (see `.ai/standards/ux-accessibility.md`)
- Respect `prefers-reduced-motion` for animated transitions

## Anti-patterns

- Duplicating server validation/business logic in Stimulus
- Broadcasting Turbo Streams without authorization scoping
- Giant "god" Stimulus controllers tied to specific pages

## References

- Agent: `.ai/agents/frontend-react-inertia-developer.yaml`
- Related: `.ai/standards/frontend.md`, `.ai/standards/ux-accessibility.md`
