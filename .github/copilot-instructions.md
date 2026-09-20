# RoR Command Center

`.ai/` is the single source of truth and works as a team. Before coding, follow
the standards in `.ai/standards/`. **Core that always applies:** `collaboration`,
`minimalism`, `development`, `project-bootstrap`, `testing`, `security`,
`git-workflow`, `code-review`, `documentation`.

Add the domain standard for the area you touch:
- Frontend → `frontend` / `hotwire` / `ux-accessibility`
- API → `api-design` · Data → `postgresql` / `mysql` · Async → `sidekiq-activejob`
- Auth/Admin → `devise-auth` / `activeadmin` · Infra → `aws-infrastructure` / `kamal-docker`
- Legacy → `legacy-rails`

Key rules:
- Rails conventions over custom abstractions
- Authorization on every mutating controller action
- Reversible database migrations with indexed foreign keys
- No secrets in code

Agents: `.ai/agents/` · Skills: `.ai/skills/` · Workflows: `.ai/workflows/` ·
Templates: `.ai/templates/`. Full index: `.ai/README.md`.

For reviews, align with `.ai/standards/code-review.md` severity levels.
Definition of Done is proportional (`.ai/standards/orchestration.md`): earn artifacts by complexity/risk; never skip safety.
