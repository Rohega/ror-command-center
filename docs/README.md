# Documentation map

Three doors. Pick one and ignore the rest until you need them.

| I want to… | Start here |
|------------|------------|
| **Install / use** the framework in a Rails project | [User Manual](USER-MANUAL.md) · [INSTALL (Path A)](INSTALL.md) · [integrations/](integrations/) |
| **Contribute** to this kit (skills, agents, adapters) | [CONTRIBUTING.md](../CONTRIBUTING.md) · [how-to/use-agents.md](how-to/use-agents.md) · [how-to/create-specialist-agent.md](how-to/create-specialist-agent.md) |
| Study the **warehouse WMS example** (not the framework) | [Example index below](#example-only-warehouse-wms) · [examples/warehouse-wms/](../examples/warehouse-wms/) |

For AI sessions (not humans): root [`AGENTS.md`](../AGENTS.md), [`CLAUDE.md`](../CLAUDE.md), or [`.ai/README.md`](../.ai/README.md).

---

## Install / use

1. [User Manual](USER-MANUAL.md) — choose Path A (IDE), Path B (Ollama), or Docker.
2. [INSTALL.md](INSTALL.md) — step-by-step for Path A (`install.sh`).
3. Platform guides: [integrations/](integrations/) (Cursor, Claude Code, Ollama, Codex, …).
4. Daily use: [how-to/use-agents.md](how-to/use-agents.md) · [how-to/run-workflows.md](how-to/run-workflows.md) · [rorcc-cli.md](rorcc-cli.md).

## Contribute to the kit

1. [CONTRIBUTING.md](../CONTRIBUTING.md) — branching, PR expectations, contributor checklist.
2. Extend specialists: [how-to/create-specialist-agent.md](how-to/create-specialist-agent.md).
3. Canonical definitions: [`.ai/README.md`](../.ai/README.md).

## EXAMPLE ONLY — warehouse WMS

These artifacts live under `docs/` for historical/reference reasons. They are **not** documentation of RoR Command Center itself. Do not treat them as the product of this repository.

| Artifact | Path |
|----------|------|
| Feature spec | [specs/warehouse-mvp.md](specs/warehouse-mvp.md) |
| User stories | [stories/warehouse-mvp/](stories/warehouse-mvp/) |
| Design | [design/warehouse-mvp.md](design/warehouse-mvp.md) |
| ADRs (stock, outbound, ERP, …) | [architecture/](architecture/) (`adr-0001` … `adr-0005`, reviews) |
| Phase 0 runbook | [runbooks/warehouse-mvp-phase-0-kickoff.md](runbooks/warehouse-mvp-phase-0-kickoff.md) |
| Runnable example app bootstrap | [examples/warehouse-wms/](../examples/warehouse-wms/) |

Install them into a project only with `./install.sh --with-examples <target>`.
