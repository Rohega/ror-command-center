# Native Agent Orchestration

Portable runtime policy for Cursor, Claude Code, Codex, and future agent
harnesses. This standard complements `orchestration.md`; it does not replace the
workflow router.

## Authority boundary

**The RoR Command Center Task Router is authoritative about what work exists.**

Classify the request once with the deterministic S/M/L/XL + risk-signal router,
then honor `applies_when`, path routing, gates, and explicit human overrides.
Native agent runtimes may decide **how to execute selected work**, but they must
not reclassify the request, re-add omitted phases, or invent artifacts.

Agent descriptions are capability/discovery metadata. They are not permission to
bypass the router.

## Default execution shape

1. **Lead agent owns the task.** It keeps the user context, integrates results,
   resolves conflicts, and produces the final answer.
2. **Explore before delegating when needed.** For an unfamiliar or broad
   codebase, use the runtime's built-in read-only explorer/scout if available.
   Do not create a custom RORCC explorer when the runtime already provides one.
   Skip exploration for obvious size-S local changes.
3. **Use skills for bounded procedures.** Prefer a skill in the current context
   when the work is single-purpose and does not benefit from context isolation.
4. **Use RORCC specialists for isolated ownership.** Spawn only specialists whose
   domain is selected by the workflow/router or clearly required by the task.
   Do not wake every specialist because it exists.
5. **Parallelize only independent workstreams.** Prefer one active specialist.
   Use up to two in parallel when L/XL work cleanly separates (for example
   backend and frontend) and neither depends on the other's unfinished output.
6. **Lead agent synthesizes once.** Subagents return concise findings/diffs;
   avoid chains of agents reviewing identical context.

## Architect / reviewer escalation

Use a strong architect or independent reviewer only when the extra reasoning is
earned. Trigger it at one of these checkpoints:

- **Before implementation** for size XL, `architecture_changed`, or a genuinely
  cross-cutting technical decision.
- **After the same implementation/debugging failure occurs twice** and the next
  attempt would otherwise repeat the same hypothesis.
- **Before declaring done** for L/XL or high-risk work (`auth_changed`,
  destructive/complex `database_changed`, `infrastructure_changed`) when an
  equivalent architecture/QA/security review has not already run.

Do not add a duplicate reviewer when the selected RORCC QA/security/architecture
phase already provides independent verification.

## Research delegation

Use a researcher/web/documentation subagent only when the task needs current or
external information that is not already in the repository or loaded docs.
Repository facts should be discovered from the repository, not researched on
the web.

## Runtime mapping

| Runtime | Native capability to prefer | RORCC adapter |
|---------|-----------------------------|---------------|
| Cursor | Built-in exploration + native project subagents / Task | `.cursor/agents/`, `.cursor/rules/` |
| Claude Code | Built-in Explore/Plan + project subagents; agent teams only when peers must coordinate | `.claude/agents/`, `CLAUDE.md` |
| Codex | `AGENTS.md` + harness multi-agent delegation when available | `AGENTS.md` |
| Other AGENTS.md tools | Their native delegation primitives | `AGENTS.md` + `.ai/` |

Do not force a lowest-common-denominator runtime. RORCC owns roles, skills,
workflow selection, safety, and Definition of Done; each platform owns context
isolation, model selection, parallel execution, and native exploration.

## Cost / context rules

- No model call just to choose the next RORCC phase.
- Do not spawn a subagent for a one-line reversible change.
- Prefer native read-only exploration over loading many unrelated files into the
  lead context.
- Pass the minimum context a subagent needs: task, relevant canonical role,
  relevant skill, and affected paths.
- More agents are not inherently more thorough. Add one only when it provides
  isolation, parallelism, or independent judgment.

## Completion contract

Before the lead agent says the task is complete:

1. Required selected checks/gates have passed.
2. No subagent has an unresolved BLOCKING finding.
3. Independent workstreams have been integrated and conflicts resolved.
4. The final response states what changed, what was verified, and any remaining
   limitation without replaying subagent transcripts.
