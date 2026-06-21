> Language: English | [Español](#versión-en-español)

# Runbook: New Project — Docker Bootstrap (no local Ruby/Rails)

**Goal:** Create a brand-new, runnable Rails app with the `.ai/` framework using only Docker on the host.
**Audience:** Any developer starting a fresh project (e.g. `tallerflow`).
**Prerequisites:** Docker Desktop running (WSL integration enabled on Windows); Git. No Ruby/Rails/Node on the host.
**Last updated:** 2026-06-20 · **Owner:** Documentation Writer

---

## Step 1 — Link the `rorcc` CLI (one time)

From your clone of the framework repo:

```bash
cd /path/to/ror-command-center
./install.sh --install-cli
```

If `~/.local/bin` is not on your `PATH`, add it, then verify:

```bash
rorcc help
```

## Step 2 — Create the Dockerized project

```bash
rorcc init --docker ~/projects/tallerflow
```

This runs end to end (a few minutes on first run):

1. Generates the Rails app inside a throwaway `ruby:3.3` container — nothing is installed on your host.
2. Drops in the generic **MySQL** dev stack (`Dockerfile.dev`, `docker-compose.yml`, `config/database.yml`, `bin/docker-entrypoint.sh`, `.env`, `.dockerignore`).
3. Wires the mandatory **RSpec** test stack (RSpec + FactoryBot + SimpleCov + `config.generators :rspec`) instead of Minitest — see `.ai/standards/project-bootstrap.md`.
4. Installs the `.ai/` framework (`.ai/`, `.cursor/`, `.claude/`, `AGENTS.md`, `CLAUDE.md`).
5. Builds the dev image, runs `bundle install`, and initializes a git repo with an initial commit.

The database name is derived from the project directory (e.g. `tallerflow_development`). Override it via `DATABASE_NAME` in the generated `.env`.

## Step 3 — Create the database and run the app

```bash
cd ~/projects/tallerflow
docker compose run --rm web rails db:create db:migrate
docker compose up
```

Open http://localhost:3000. MySQL is reachable from the host at `localhost:3307`.

## Step 4 — Develop using the framework

Pick how you want the AI specialists to run:

- **Cursor (no extra setup):** open the project; `.cursor/rules` + `AGENTS.md` load automatically. Ask it to *"follow the new-feature workflow"*.
- **Local (Ollama):** `rorcc workflow new-feature`
- **Cloud (API key):** `rorcc workflow new-feature --cloud`

## Step 5 — Push to your own repo (optional)

```bash
cd ~/projects/tallerflow
gh repo create tallerflow --private --source=. --remote=origin --push
```

---

## Common Docker commands

```bash
docker compose run --rm web rails console
docker compose run --rm web bundle exec rspec
docker compose run --rm web rails generate model Widget name:string
docker compose exec web bash
docker compose down                 # stop services
```

## Troubleshooting

| Symptom | Cause / Fix |
|---------|-------------|
| `Docker daemon not reachable` | Start Docker Desktop; on Windows enable WSL integration. |
| `... already contains a Gemfile` | Target is not empty — pick a new directory. |
| `rails: executable file not found` | Ensure `bin/docker-entrypoint.sh` exists and `entrypoint` is set in `docker-compose.yml`. |
| Port 3000/3307 in use | Set `RAILS_PORT` / `MYSQL_PORT` in `.env`. |
| DB connection refused on first `up` | The `db` service has a healthcheck; `web` waits for it. Retry after it reports healthy. |

## Rollback

The project is isolated from the framework repo. To start over:

```bash
docker compose down -v             # remove containers + volumes (drops DB data)
rm -rf ~/projects/tallerflow       # delete the generated app
```

## References

- CLI reference: `docs/rorcc-cli.md`
- Default development flow: `.ai/workflows/new-feature.yaml`
- Worked example (WMS): `examples/warehouse-wms/`

---

## Versión en español

# Runbook: Proyecto nuevo — Arranque con Docker (sin Ruby/Rails local)

**Objetivo:** Crear una app Rails nueva y ejecutable con el framework `.ai/` usando solo Docker en el host.
**Audiencia:** Cualquier desarrollador que inicia un proyecto desde cero (p. ej. `tallerflow`).
**Requisitos:** Docker Desktop activo (integración WSL en Windows); Git. Sin Ruby/Rails/Node en el host.
**Última actualización:** 2026-06-20 · **Responsable:** Documentation Writer

---

### Paso 1 — Enlazar el CLI `rorcc` (una sola vez)

Desde tu clon del repo del framework:

```bash
cd /ruta/a/ror-command-center
./install.sh --install-cli
```

Si `~/.local/bin` no está en tu `PATH`, agrégalo y verifica:

```bash
rorcc help
```

### Paso 2 — Crear el proyecto Dockerizado

```bash
rorcc init --docker ~/projects/tallerflow
```

Esto corre de principio a fin (unos minutos la primera vez):

1. Genera la app Rails dentro de un contenedor `ruby:3.3` desechable — no se instala nada en tu host.
2. Coloca el stack de desarrollo genérico con **MySQL** (`Dockerfile.dev`, `docker-compose.yml`, `config/database.yml`, `bin/docker-entrypoint.sh`, `.env`, `.dockerignore`).
3. Configura el stack de pruebas **RSpec** obligatorio (RSpec + FactoryBot + SimpleCov + `config.generators :rspec`) en lugar de Minitest — ver `.ai/standards/project-bootstrap.md`.
4. Instala el framework `.ai/` (`.ai/`, `.cursor/`, `.claude/`, `AGENTS.md`, `CLAUDE.md`).
5. Construye la imagen, ejecuta `bundle install` e inicializa git con un commit inicial.

El nombre de la BD se deriva del directorio del proyecto (p. ej. `tallerflow_development`). Cámbialo con `DATABASE_NAME` en el `.env` generado.

### Paso 3 — Crear la base de datos y levantar la app

```bash
cd ~/projects/tallerflow
docker compose run --rm web rails db:create db:migrate
docker compose up
```

Abre http://localhost:3000. MySQL es accesible desde el host en `localhost:3307`.

### Paso 4 — Desarrollar con el framework

Elige cómo correr a los especialistas IA:

- **Cursor (sin configuración extra):** abre el proyecto; `.cursor/rules` + `AGENTS.md` se cargan solos. Pídele *"sigue el workflow new-feature"*.
- **Local (Ollama):** `rorcc workflow new-feature`
- **Nube (API key):** `rorcc workflow new-feature --cloud`

### Paso 5 — Subir a tu propio repo (opcional)

```bash
cd ~/projects/tallerflow
gh repo create tallerflow --private --source=. --remote=origin --push
```

---

### Comandos Docker útiles

```bash
docker compose run --rm web rails console
docker compose run --rm web bundle exec rspec
docker compose run --rm web rails generate model Widget name:string
docker compose exec web bash
docker compose down                 # detener servicios
```

### Solución de problemas

| Síntoma | Causa / Solución |
|---------|------------------|
| `Docker daemon not reachable` | Abre Docker Desktop; en Windows activa la integración WSL. |
| `... already contains a Gemfile` | El destino no está vacío — elige otro directorio. |
| `rails: executable file not found` | Verifica que exista `bin/docker-entrypoint.sh` y `entrypoint` en `docker-compose.yml`. |
| Puerto 3000/3307 ocupado | Define `RAILS_PORT` / `MYSQL_PORT` en `.env`. |
| Conexión a BD rechazada en el primer `up` | El servicio `db` tiene healthcheck; `web` lo espera. Reintenta cuando esté saludable. |

### Rollback

El proyecto es independiente del repo del framework. Para empezar de cero:

```bash
docker compose down -v             # elimina contenedores + volúmenes (borra datos de BD)
rm -rf ~/projects/tallerflow       # borra la app generada
```

### Referencias

- Referencia del CLI: `docs/rorcc-cli.md`
- Flujo de desarrollo por defecto: `.ai/workflows/new-feature.yaml`
- Ejemplo completo (WMS): `examples/warehouse-wms/`
