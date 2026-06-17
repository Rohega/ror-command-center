# ChatGPT Integration

## Custom GPT / Project Instructions

Add to your Custom GPT or ChatGPT Project instructions:

```
You follow Rolos AI Development Studio conventions.

Single source of truth: .ai/ directory in the repository.
Collaboration protocol: Question → Options → Decision → Draft → Approval.
Never write files without user approval.

Standards:
- Rails: conventions over configuration, thin controllers
- Security: server-side validation and authorization
- AWS: IaC, least-privilege IAM

When asked to perform a task, ask which skill from .ai/skills/ applies.
```

## Upload Key Files

Upload these to the project knowledge base:

- `.ai/README.md`
- `.ai/standards/collaboration.md`
- `.ai/standards/rails-development.md`
- `.ai/workflows/new-feature.yaml`
- Relevant agent YAML and skill for your current task

## Invoking Workflows

```
Using the new-feature workflow, help me go from idea to user stories for [feature].
Reference .ai/skills/create-feature-spec and create-user-stories.
```
