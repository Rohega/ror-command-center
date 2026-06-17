# WMS MVP — Arranque con Docker (sin Rails local)

Genera la app en un **directorio hermano** (`../warehouse-wms`) y luego la subes a **tu propio repo**.

## Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) con integración WSL activada
- Git
- **No** necesitas Ruby/Rails en el host

## Inicio rápido (3 comandos)

```bash
cd examples/warehouse-wms
chmod +x bin/*.sh
./bin/bootstrap-docker.sh
```

Luego (**orden importante** — Devise antes de `db:migrate`):

```bash
cd ../warehouse-wms
docker compose run --rm web bash bin/setup-devise.sh
docker compose run --rm web rails db:create db:migrate
docker compose up
```

`setup-devise.sh` genera Devise, añade `role` a la migración `users` y elimina `add_role_to_users` duplicada.

Abre http://localhost:3000

## Pasar a repo propio

Guía completa: **[docs/MIGRATE-TO-OWN-REPO.md](docs/MIGRATE-TO-OWN-REPO.md)**

```bash
cd ../warehouse-wms
gh repo create warehouse-wms --private --source=. --remote=origin --push
```

## Estructura tras bootstrap

```
warehouse-wms/          ← TU repo (independiente del framework)
├── docker-compose.yml
├── Dockerfile.dev
├── app/
│   └── services/warehouse/stock_updater.rb
├── db/migrate/         ← Fase 0 WMS
├── docs/               ← spec, ADRs, stories (copiados)
├── .ai/                ← agentes (copiados, opcional)
└── Gemfile
```

## Comandos Docker útiles

Todos los comandos Rails van con `bundle exec` (o usa el entrypoint `bin/docker-entrypoint.sh`):

```bash
docker compose run --rm web rails generate devise:install
docker compose run --rm web rails db:migrate
docker compose run --rm web bundle exec rspec
docker compose run --rm web rails console
docker compose exec web bash
```

Si ves `rails: executable file not found`, copia `bin/docker-entrypoint.sh` del framework y añade `entrypoint` en `docker-compose.yml` (ver guía de migración).

## Ramas Fase 0

| Rama | Contenido |
|------|-----------|
| `feature/warehouse-auth-rbac` | Devise + roles + Pundit |
| `feature/warehouse-master-data` | Catálogo + almacenes |
| `feature/warehouse-stock-core` | StockUpdater + migraciones stock |

Ver `docs/runbooks/warehouse-mvp-phase-0-kickoff.md` (copiado al bootstrap).

## Documentación en el framework (referencia)

- Spec: `../../docs/specs/warehouse-mvp.md`
- ADRs: `../../docs/architecture/adr-0001` … `0005`
