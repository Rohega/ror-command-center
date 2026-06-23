# RoR Command Center — Manual de usuario

> Guía práctica para usar RoR Command Center en tu proyecto Rails con cualquier
> agente de IA (Cursor, Claude Code, Codex, Copilot…). Pensada para ponerte a
> producir en una sola sesión.

Última actualización: 2026-06-22

---

## Inicio rápido — ¿qué quieres hacer?

¿Nuevo aquí? Esta tabla te lleva directo a la sección correcta (detalle en §3):

| Quiero… | Ve a | ¿Necesita Ollama? |
|---------|------|-------------------|
| Usar el framework en mi proyecto Rails con Cursor/Claude | §3.1 (Ruta A) | No |
| Correr los agentes en local, sin nube ni API keys | §3.2 (Ruta B, Ollama) | Sí |
| Arrancar un proyecto nuevo sin Ruby/Rails local | §3.3 (Docker) | No |

Son **decisiones independientes**, fáciles de confundir:

- **Cómo creas el proyecto:** Ruby/Rails local · solo Docker (`rorcc init --docker`).
- **Cómo corres los agentes:** Cursor/Claude (nube) · Ollama (local) · API key (`--cloud`).

Ollama es **solo** para correr agentes en local; nunca hace falta para instalar el
framework ni para crear el proyecto.

---

## 1. Qué es (en 30 segundos)

RoR Command Center convierte tu repo en un **equipo senior de Rails** dirigido por
IA: 8 roles especialistas, skills reutilizables, workflows de punta a punta y
standards de ingeniería de nivel producción.

La clave: **todo vive en `.ai/` (la fuente única de verdad)**. Las carpetas de cada
plataforma (`.cursor/`, `.claude/`, `.github/`, `AGENTS.md`) son **adaptadores
delgados** que apuntan a `.ai/` sin duplicar contenido.

| Concepto | Dónde vive | En palabras simples |
|----------|-----------|---------------------|
| **Standard** | `.ai/standards/` | El "cómo construimos las cosas". |
| **Agent** | `.ai/agents/` | Un rol del equipo (ej. Rails Architect). |
| **Skill** | `.ai/skills/` | Una tarea concreta (ej. "redactar un feature spec"). |
| **Workflow** | `.ai/workflows/` | Varios pasos encadenados (idea → deploy). |
| **Template** | `.ai/templates/` | Plantilla para generar artefactos (ADR, QA plan…). |
| **Adaptador** | `.cursor/`, `.claude/`, `AGENTS.md` | Le dice a cada IA que use `.ai/`. |

---

## 2. El "router" de `.ai` (cómo se garantiza que se use siempre)

El problema clásico: el agente *menciona* los standards pero no siempre los **lee**.
Para cerrarlo, el framework carga `.ai/` por dos vías complementarias:

1. **Núcleo siempre presente.** Estos 9 standards se cargan en cada sesión porque
   aplican a todo trabajo: `collaboration`, `minimalism`, `development`,
   `project-bootstrap`, `testing`, `security`, `git-workflow`, `code-review`,
   `documentation`.
2. **Standards de dominio on-demand.** El resto (frontend, api, datos, async,
   auth, infra, legacy) se cargan en cuanto tocas su área — así no se infla el
   contexto innecesariamente (principio de minimalismo).

Cómo se materializa en cada plataforma:

| Plataforma | Mecanismo del router | Se carga… |
|------------|----------------------|-----------|
| **Cursor** | `.cursor/rules/ai-index.mdc` (`alwaysApply: true`) | automáticamente en cada chat |
| **Claude Code** | `CLAUDE.md` (`@`-referencias) | al iniciar `claude` |
| **Codex** | `AGENTS.md` (auto-load) | al iniciar sesión |
| **Copilot** | `.github/copilot-instructions.md` | automáticamente |

> En Cursor, además, cada standard de dominio tiene su regla `.mdc` por glob que se
> activa al abrir archivos de ese tipo (`rails.mdc` → `app/**/*.rb`, etc.). El
> router cubre el caso en que **ninguna** regla por glob se dispara (repos nuevos,
> trabajo en Markdown/YAML, planificación en el chat).

---

## 3. Instalación — elige tu ruta

Hay **dos formas independientes** de usar el framework. Es fácil confundirlas:

| Ruta | Para qué | Cómo | Qué instala |
|------|----------|------|-------------|
| **A · IDE en la nube** (la más común) | Usar el framework dentro de tu proyecto Rails con Cursor, Claude Code, Codex… | `install.sh` copia el core a tu proyecto | Nada pesado: solo archivos de config (`.ai/`, `.cursor/`, `.claude/`…) |
| **B · IA local** (sin nube, sin API keys) | Correr el equipo de especialistas en tu propia máquina con el CLI `rorcc` | `setup.sh` instala Ollama + un modelo | Ollama + un modelo local de varios GB |

> La Ruta A **no** instala Ollama. La Ruta B es la única que instala un motor de
> IA en tu equipo. Puedes hacer ambas.

### 3.1 Ruta A — añadir el framework a un proyecto (nube)

Clona el framework y ejecútalo apuntando a tu proyecto:

```bash
git clone https://github.com/Rohega/ror-command-center.git
cd ror-command-center
./install.sh /ruta/a/tu-proyecto
```

Copia el **core** y crea el scaffolding vacío de `docs/`. No sobrescribe archivos
existentes salvo que pases `--force`.

| Flag | Efecto |
|------|--------|
| `--dry-run` | Muestra qué copiaría sin escribir nada |
| `--force` | Sobrescribe archivos existentes |
| `--backup` | Guarda los conflictos como `<archivo>.bak` |
| `--with-examples` | Copia también `examples/` y docs del ejemplo warehouse |

Verifica la instalación:

```bash
cd /ruta/a/tu-proyecto
test -f .cursor/rules/ai-index.mdc && echo "router OK"
ls .ai/standards | wc -l   # debería listar los standards
```

Si abres el proyecto en Cursor, el hook de inicio (`detect-gaps.sh`) avisa si
falta `.ai/` o el router.

**Actualizar más adelante:** `.ai/` es la fuente única de verdad; los adaptadores
(`.cursor/`, `.claude/`, `AGENTS.md`) se regeneran. Para refrescar un proyecto ya
instalado, necesitas `--force` (sin él, los archivos existentes se omiten):

```bash
cd ror-command-center && git pull
./install.sh --force --backup /ruta/a/tu-proyecto
```

### 3.2 Ruta B — IA local con Ollama (`rorcc`)

Corre los especialistas en tu propia PC, sin nube ni costo por token.

**Antes de instalar, comprueba que tu equipo aguanta los modelos** (funciona en
cualquier máquina, incluso antes de instalar nada):

```bash
bash scripts/check-machine.sh
```

Reporta SO, RAM, CPU, disco y GPU, y recomienda el modelo según tu RAM:

| RAM | Modelo | Experiencia |
|-----|--------|-------------|
| 8–16 GB | `qwen2.5-coder:7b` | Funciona; tareas del día a día |
| 24–32 GB | `qwen2.5-coder:14b` | Mejor razonamiento |
| 48 GB+ | `qwen2.5-coder:32b` | Mejor calidad local |
| < 8 GB | — | No recomendado (lento/limitado) |

Instala todo con un comando — instala Ollama, descarga el modelo, deja listo el
CLI `rorcc` y compila los especialistas (`setup.sh` corre el chequeo de equipo
automáticamente y elige el modelo por ti):

```bash
cd ror-command-center && ./setup.sh   # pregunta una vez e instala todo
rorcc                                 # menú interactivo: elige un especialista por número
```

¿Prefieres un one-liner remoto? Por el pipe corre **sin interacción**, así que
acéptalo de antemano con `RORCC_YES=1`:

```bash
curl -fsSL https://raw.githubusercontent.com/Rohega/ror-command-center/main/setup.sh | RORCC_YES=1 bash
```

Comandos útiles después de instalar:

```bash
rorcc doctor                  # diagnóstico: Ollama, modelos, daemon, entorno
rorcc agent rails-architect   # chatear con un especialista
rorcc skill create-feature-spec
rorcc workflow new-feature
```

> **Dónde ejecutar `rorcc`.** Los comandos que leen el framework (`agent`,
> `skill`, `workflow`, `build-agent`, `update`, `doctor`) necesitan encontrar la
> carpeta `.ai/`. Ejecútalos **dentro de una carpeta que la contenga**: un
> proyecto creado con `rorcc init <nombre>` o el repositorio clonado. Desde
> cualquier otra carpeta verás `no .ai/ framework found`. Si instalaste con el
> one-liner `curl … | bash`, el framework queda en `~/.ror-command-center`.

En **Windows + WSL2**, sube el límite de memoria de WSL en `.wslconfig` si hace
falta (el modelo necesita su tamaño completo libre en RAM). Guía completa de la
ruta local: `docs/integrations/ollama.md`.

### 3.3 Arrancar un proyecto NUEVO con Docker (`rorcc init --docker`)

¿Quieres una app Rails nueva y ejecutable con el framework ya integrado, **sin
instalar Ruby/Rails/Node** en tu equipo? `rorcc init --docker` la genera dentro de
contenedores desechables — **el único requisito es Docker**.

```bash
./install.sh --install-cli       # una vez: enlaza el comando 'rorcc'
rorcc init --docker tallerflow   # genera la app Rails dockerizada + framework
```

> **Docker ≠ Ollama.** Crear el proyecto con Docker **no** necesita Ollama. Son
> dos decisiones separadas:
>
> | Decisión | Opciones | ¿Necesita Ollama? |
> |----------|----------|-------------------|
> | **Cómo creas el proyecto** | Ruby/Rails local · **solo Docker** (`rorcc init --docker`) | No |
> | **Cómo corres los agentes IA** | Cursor/Claude (nube) · **Ollama** (local) · API key (`--cloud`) | Solo la opción Ollama |
>
> Puedes crear con Docker y luego usar Cursor (nube) **sin Ollama**.

Guía paso a paso (EN/ES), con comandos, troubleshooting y rollback:
`docs/runbooks/new-project-docker-bootstrap.md`.

### 3.4 Desinstalar / limpiar (`uninstall.sh`)

¿Quieres revertir lo que instaló `setup.sh`? Usa `./uninstall.sh` (o `rorcc
uninstall`). Es interactivo —pregunta por cada grupo— y puedes previsualizarlo
con `--dry-run` antes de borrar nada.

```bash
./uninstall.sh                 # especialistas compilados, comando 'rorcc', framework descargado
./uninstall.sh --models        # además borra los modelos base descargados (varios GB)
./uninstall.sh --ollama        # además desinstala Ollama por completo (binario, servicio, ~/.ollama)
./uninstall.sh --project <dir> # borra de <dir> los archivos que copió install.sh
./uninstall.sh --dry-run       # muestra qué se borraría, sin tocar nada
```

> **Seguridad.** No toca `jq`, `zstd` ni `git` (utilidades generales). En modo
> `--project`, conserva las carpetas de `docs/` que contengan archivos tuyos
> (specs, ADRs, etc.) y nunca borra el código de tu app. Desinstalar Ollama en
> Linux pide `sudo` (binario y servicio del sistema).

---

## 4. Uso diario

### 4.1 Flujo recomendado (Cursor)

1. Abre el proyecto en Cursor — el router carga solo.
2. Planifica en **modo Ask**, implementa en **modo Agent**.
3. Para tareas grandes, deja que el agente siga un workflow y se detenga en cada
   fase para tu aprobación.

### 4.2 Recetas copy-paste

**Redactar un feature spec (skill + agent):**

```
Actúa como el agent en .ai/agents/product-owner.yaml y sigue
.ai/skills/create-feature-spec/SKILL.md para un spec de "transferencia de stock
entre almacenes". Hazme preguntas primero; luego guárdalo en docs/specs/.
```

**Revisar un modelo contra los standards (agent + standard):**

```
Actúa como el agent en .ai/agents/qa-engineer.yaml. Revisa app/models/invoice.rb
contra .ai/standards/development.md y .ai/standards/security.md.
Lista los problemas por severidad; no edites archivos todavía.
```

**Ejecutar el workflow completo de nueva feature:**

```
Ejecuta .ai/workflows/new-feature.yaml para "transferencia de stock entre
almacenes". Detente tras cada fase y espera mi aprobación.
```

**Reforzar el framework en un chat puntual:**

```
Para este proyecto, trata .ai/ como la fuente única de verdad. Antes de
implementar, carga el agent de .ai/agents/, el skill de .ai/skills/ y los
standards de .ai/standards/. Sigue el protocolo de colaboración: pregunta,
ofrece opciones, redacta y espera mi aprobación antes de escribir archivos.
```

> Tip: usa `@`-menciones en Cursor para adjuntar el archivo exacto, p. ej.
> `@.ai/skills/create-feature-spec/SKILL.md`.

### 4.3 Otras plataformas

- **Claude Code:** ejecuta `claude`; invoca skills con `/create-feature-spec`,
  `/qa-plan`, etc. Ver `docs/integrations/claude-code.md`.
- **Codex / Copilot:** `AGENTS.md` y `.github/copilot-instructions.md` se cargan
  solos. Ver `docs/integrations/codex.md` y `docs/integrations/copilot.md`.

---

## 5. El pipeline de una feature (Definition of Done)

Toda feature sigue: **Idea → Spec → Arquitectura → Plan → Desarrollo → Tests →
Documentación → Deploy**. No se considera terminada hasta cumplir el DoD:

- [ ] Tests RSpec de los caminos críticos.
- [ ] Sin specs pendientes/saltados sin ticket.
- [ ] `ponytail-review` sin sobre-ingeniería sin resolver.
- [ ] `qa-plan` sin hallazgos BLOQUEANTES.
- [ ] Documentación del módulo en `docs/`.
- [ ] Trabajo en rama `feature/<ticket>-<slug>` (nunca en `main`).

Detalle: `.cursor/rules/workflow-gates.mdc` y `.ai/workflows/new-feature.yaml`.

---

## 6. Extender el framework

- **Nuevo standard:** créalo en `.ai/standards/`. Si quieres que se cargue
  siempre, añádelo al núcleo en `.cursor/rules/ai-index.mdc` (y, por paridad, en
  `CLAUDE.md` / `AGENTS.md`). Si es de dominio, añade su línea en la sección
  "Standards de dominio" y, opcionalmente, una regla `.mdc` por glob.
- **Nuevo skill / agent / workflow:** créalo bajo `.ai/` y lístalo en el router.
  Para compilar un **agente especialista** como modelo local (`rorcc-<nombre>`) y
  chatear con él, sigue la guía paso a paso:
  `docs/how-to/create-specialist-agent.md`.
- **Regla específica del proyecto:** añade un `.mdc` en `.cursor/rules/` que
  **referencie** `.ai/standards/` — nunca copies el texto del standard.

> Regla de oro: una sola fuente de verdad (`.ai/`). Los adaptadores apuntan, no
> duplican.

---

## 7. Solución de problemas

| Síntoma | Causa probable | Solución |
|---------|----------------|----------|
| `no .ai/ framework found` | Estás fuera de una carpeta con `.ai/` | `cd` a tu proyecto (`rorcc init`) o al repo clonado (`~/.ror-command-center`) y reintenta |
| Falla la instalación de Ollama al descomprimir | Falta `zstd` (Linux mínimo/WSL) | `sudo apt-get install zstd` y vuelve a correr `setup.sh` |
| Tras `curl … \| bash` no aparece `rorcc` ni los especialistas | Versión antigua del one-liner sin auto-descarga | Re-ejecuta `setup.sh` (ahora clona el framework en `~/.ror-command-center`) o clónalo a mano |
| El agente ignora los standards | El router no se instaló | `test -f .cursor/rules/ai-index.mdc`; re-ejecuta `install.sh --force` |
| Una regla de dominio no se activa | Tipo de archivo no coincide con el glob | `@`-menciona el standard o la regla |
| El agente edita sin preguntar | Estás en modo Agent | Pide "pregunta antes de editar" o planifica en modo Ask |
| No sé qué reglas están activas | Activación por glob | Abre un archivo de ese tipo o `@`-menciona la regla |
| Falta el equipo en un repo nuevo | Aún sin archivos Rails | El router (`ai-index.mdc`) ya garantiza el núcleo; refuerza con la receta 4.2 |

---

## 8. Glosario

- **`.ai/`** — Fuente única de verdad; todas las definiciones del framework.
- **Adaptador** — Carpeta/archivo específico de una IA que apunta a `.ai/`.
- **Router** — Mecanismo que garantiza que `.ai/` se considere siempre
  (`ai-index.mdc` en Cursor; `CLAUDE.md`/`AGENTS.md` en otras).
- **Núcleo** — Los 9 standards transversales que se cargan en cada sesión.
- **DoD (Definition of Done)** — Criterios mínimos para dar por terminado el trabajo.
- **`alwaysApply`** — Frontmatter de una regla de Cursor que la activa en todo chat.
- **Glob** — Patrón de archivos que activa una regla `.mdc` por tipo de archivo.

---

## 9. Referencias

- Índice de `.ai/`: `.ai/README.md`
- Crear un agente especialista (modelo local): `docs/how-to/create-specialist-agent.md`
- Guía Cursor: `docs/integrations/cursor.md`
- Guía Claude Code: `docs/integrations/claude-code.md`
- Guía IA local (Ollama): `docs/integrations/ollama.md`
- Protocolo de colaboración: `.ai/standards/collaboration.md`
- Gates de ingeniería: `.cursor/rules/workflow-gates.mdc`
- Instalación detallada: `docs/INSTALL.md`
