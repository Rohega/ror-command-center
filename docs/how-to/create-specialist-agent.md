> Language: English | [Español](#versión-en-español)

# Create a specialist agent (local model)

**Audience:** Anyone who already installed the local AI path (`setup.sh` + the
`rorcc` CLI). You can use a terminal; you do **not** need to know how Ollama works
internally.
**Goal:** Have your own specialist compiled as a local model (`rorcc-<name>`) and
be able to chat with it.
**Last updated:** 2026-06-22

---

## Before you start (prerequisites)

**Required:**
- [ ] `rorcc` installed and `rorcc doctor` passing.
- [ ] Ollama running (`ollama serve`) with the base model pulled
  (`qwen2.5-coder:7b` by default).
- [ ] You are **inside a folder that contains `.ai/`** — a project created with
  `rorcc init <name>` or the cloned framework repo. Elsewhere you'll see
  `no .ai/ framework found`.
- [ ] `jq` installed (`rorcc agent` requires it).

**Optional (choose only if you need it):**
- [ ] Cloud backend (`rorcc agent <name> --cloud`): if you use it you do **not**
  need to compile a local model or run Ollama at all.

> A specialist is just a `.ai/agents/<name>.yaml` file. "Compiling" it bakes that
> file plus its referenced standards into a local Ollama model named
> `rorcc-<name>`.

## Steps

1. Create the role definition at `.ai/agents/<name>.yaml`. Copy an existing one as
   a base. Every `.ai/...` path you list under `references:` is **inlined** into
   the system prompt automatically, so the model follows those standards.

```yaml
name: Performance Engineer
purpose: Diagnose and fix Rails performance problems (N+1, slow queries, caching).
responsibilities:
  - Profile endpoints and background jobs
  - Identify N+1 queries and missing indexes
rules:
  - Measure before optimizing; no speculative caching
  - Every fix backed by a benchmark or query plan
references:
  - .ai/standards/development.md
  - .ai/standards/postgresql.md
  - .ai/standards/minimalism.md
```

2. Compile the specialist — this registers `rorcc-<name>` in Ollama:

```bash
rorcc build-agent performance-engineer
```

3. Chat with it locally (or via the cloud backend, which needs no compile):

```bash
rorcc agent performance-engineer
rorcc agent performance-engineer --cloud
```

4. Edited the `.yaml` or any standard it references? Recompile so the local model
   picks up the change (the `--cloud` backend re-assembles on every run, so it
   does not need this):

```bash
rorcc update performance-engineer
```

## Verify it worked

- [ ] `rorcc build-agent` ends with `agent ready — run it with: rorcc agent <name>`.
- [ ] `ollama list` shows `rorcc-performance-engineer:latest`.
- [ ] `rorcc agent performance-engineer` opens the chat session.

## Troubleshooting

| Symptom | Cause / Fix |
|---------|-------------|
| `agent not found: …/.ai/agents/<name>.yaml` | Name doesn't match a file in `.ai/agents/`. `rorcc build-agent` prints the available agents. |
| `no .ai/ framework found` | You're outside a folder with `.ai/`. `cd` into your project or the cloned repo and retry. |
| `ollama daemon not reachable` | Start Ollama: `ollama serve`. |
| `jq is required for 'rorcc agent'` | Install `jq` (`apt install jq` / `brew install jq`). |
| `ollama create failed` | Base model not pulled: `ollama pull qwen2.5-coder:7b`. |
| `system prompt is large` / truncated | Cap it with `RORCC_MAX_CHARS=<n>` or use a larger base model. |

## Design note: one model per name, shared across projects

Models live in a **global namespace per machine**: `rorcc-<name>`, **not** per
project. There is a single `rorcc-performance-engineer` shared by all your
projects. If you recompile the same name from another project whose `.ai/`
differs, the **last build wins**. Because `rorcc init` copies the same `.ai/`
into every project, this is usually what you want (it saves ~4.7 GB per agent).
It only matters if a project customizes its own standards — then rebuild that
specialist from inside that project before using it there.

## Glossary

- **Agent / specialist** — a team role defined in `.ai/agents/<name>.yaml`.
- **Base model** — the LLM the specialist is compiled on (`qwen2.5-coder:7b`).
- **Modelfile** — the recipe Ollama uses to create `rorcc-<name>` (written to
  `.rorcc/build/<name>/`).
- **System prompt** — the `.yaml` plus its inlined standards; defines behavior.
- **Tag** — the `:latest` suffix Ollama appends to a created model name.

## Related

- CLI command reference: [docs/rorcc-cli.md](../rorcc-cli.md)
- Local AI / Ollama setup: [docs/integrations/ollama.md](../integrations/ollama.md)
- User manual, "Extender el framework": [docs/USER-MANUAL.md](../USER-MANUAL.md)

---

## Versión en español

**Audiencia:** cualquiera que ya instaló la ruta de IA local (`setup.sh` + el CLI
`rorcc`). Sabes usar la terminal; **no** necesitas conocer Ollama por dentro.
**Objetivo:** tener tu propio especialista compilado como modelo local
(`rorcc-<nombre>`) y poder chatear con él.
**Última actualización:** 2026-06-22

### Antes de empezar (prerrequisitos)

**Requerido:**
- [ ] `rorcc` instalado y `rorcc doctor` en verde.
- [ ] Ollama corriendo (`ollama serve`) con el modelo base descargado
  (`qwen2.5-coder:7b` por defecto).
- [ ] Estar **dentro de una carpeta que contenga `.ai/`** — un proyecto creado con
  `rorcc init <nombre>` o el repo clonado del framework. Fuera de ahí verás
  `no .ai/ framework found`.
- [ ] `jq` instalado (lo exige `rorcc agent`).

**Opcional (elige solo si lo necesitas):**
- [ ] Backend en la nube (`rorcc agent <nombre> --cloud`): si lo usas **no**
  necesitas compilar un modelo local ni Ollama.

> Un especialista es solo un archivo `.ai/agents/<nombre>.yaml`. "Compilarlo"
> hornea ese archivo y los standards que referencia dentro de un modelo local de
> Ollama llamado `rorcc-<nombre>`.

### Pasos

1. Crea la definición del rol en `.ai/agents/<nombre>.yaml`. Copia uno existente
   como base. Cada ruta `.ai/...` que listes en `references:` se **inlinea**
   automáticamente al system prompt, así el modelo sigue esos standards.

```yaml
name: Performance Engineer
purpose: Diagnose and fix Rails performance problems (N+1, slow queries, caching).
responsibilities:
  - Profile endpoints and background jobs
  - Identify N+1 queries and missing indexes
rules:
  - Measure before optimizing; no speculative caching
  - Every fix backed by a benchmark or query plan
references:
  - .ai/standards/development.md
  - .ai/standards/postgresql.md
  - .ai/standards/minimalism.md
```

2. Compila el especialista — registra `rorcc-<nombre>` en Ollama:

```bash
rorcc build-agent performance-engineer
```

3. Chatea con él en local (o vía nube, que no necesita compilar):

```bash
rorcc agent performance-engineer
rorcc agent performance-engineer --cloud
```

4. ¿Editaste el `.yaml` o algún standard que referencia? Recompila para que el
   modelo local recoja el cambio (el backend `--cloud` reensambla en cada
   arranque, así que no lo necesita):

```bash
rorcc update performance-engineer
```

### Verifica que funcionó

- [ ] `rorcc build-agent` termina con `agent ready — run it with: rorcc agent <nombre>`.
- [ ] `ollama list` muestra `rorcc-performance-engineer:latest`.
- [ ] `rorcc agent performance-engineer` abre la sesión de chat.

### Solución de problemas

| Síntoma | Causa / Solución |
|---------|------------------|
| `agent not found: …/.ai/agents/<nombre>.yaml` | El nombre no coincide con un archivo en `.ai/agents/`. `rorcc build-agent` lista los disponibles. |
| `no .ai/ framework found` | Estás fuera de una carpeta con `.ai/`. `cd` a tu proyecto o al repo clonado y reintenta. |
| `ollama daemon not reachable` | Arranca Ollama: `ollama serve`. |
| `jq is required for 'rorcc agent'` | Instala `jq` (`apt install jq` / `brew install jq`). |
| `ollama create failed` | Falta el modelo base: `ollama pull qwen2.5-coder:7b`. |
| `system prompt is large` / truncado | Limítalo con `RORCC_MAX_CHARS=<n>` o usa un modelo base más grande. |

### Nota de diseño: un modelo por nombre, compartido entre proyectos

Los modelos viven en un **namespace global por máquina**: `rorcc-<nombre>`, **no**
por proyecto. Hay un solo `rorcc-performance-engineer` compartido por todos tus
proyectos. Si recompilas el mismo nombre desde otro proyecto con un `.ai/`
distinto, **gana el último build**. Como `rorcc init` copia el mismo `.ai/` a cada
proyecto, normalmente es lo deseable (ahorra ~4.7 GB por agente). Solo importa si
un proyecto personaliza sus propios standards — en ese caso recompila ese
especialista desde dentro de ese proyecto antes de usarlo ahí.

### Glosario

- **Agente / especialista** — un rol del equipo definido en `.ai/agents/<nombre>.yaml`.
- **Modelo base** — el LLM sobre el que se compila el especialista (`qwen2.5-coder:7b`).
- **Modelfile** — la receta que Ollama usa para crear `rorcc-<nombre>` (se escribe
  en `.rorcc/build/<nombre>/`).
- **System prompt** — el `.yaml` más sus standards inlineados; define el comportamiento.
- **Tag** — el sufijo `:latest` que Ollama añade al nombre del modelo creado.

### Relacionado

- Referencia de comandos del CLI: [docs/rorcc-cli.md](../rorcc-cli.md)
- Instalación de IA local / Ollama: [docs/integrations/ollama.md](../integrations/ollama.md)
- Manual de usuario, "Extender el framework": [docs/USER-MANUAL.md](../USER-MANUAL.md)
