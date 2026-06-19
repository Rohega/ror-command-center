> Language: English | [Español](#versión-en-español)

# Runbook: WMS MVP — Phase 0 Kickoff

**Goal:** Start implementation in a Rails repository with the 3 foundational branches merged in 5–7 days.  
**Audience:** 2–3 backend/frontend developers  
**Prerequisites:** ADRs 0001–0005 Accepted, DBA review Approved

---

## Pre-checklist (day 0)

- [ ] Rails repository created or identified (this is not the framework repo)
- [ ] MySQL 8 available locally or via Docker
- [ ] Copy `.ai/` from the framework into the app repo (optional)
- [ ] Copy `examples/warehouse-wms/` as a starting point
- [ ] Create a board with the 3 Phase 0 branches assigned

---

## Branch 1: `feature/warehouse-auth-rbac` (Dev C, ~2 days)

**Stories:** US-040

### Tasks

1. `rails generate devise:install` + `devise User name:string`
2. Migration `AddRoleToUsers` (see example)
3. `User` model with `enum :role, { admin: 0, supervisor: 1, operario: 2, consulta: 3 }`
4. `ApplicationController` + `authenticate_user!`
5. Install Pundit; `ApplicationPolicy`; base policies
6. Seed: `admin@example.com` / password in credentials
7. Minimal Inertia layout or ERB with login

### Definition of Done

- [ ] Working login/logout
- [ ] 4 roles in the DB
- [ ] Request spec: an operario cannot access an admin route

### PR → merge to `main`

---

## Branch 2: `feature/warehouse-master-data` (Dev A, ~3 days)

**Stories:** US-001, US-002, US-003, US-004  
**Depends on:** auth merge (for policies)

### Tasks

1. Migrations: warehouses, categories, products, locations, external_references
2. Models in the `Warehouse::` namespace (ADR-0004):
   - `Warehouse::Warehouse`, `Category`, `Product`, `Location`
   - Global `ExternalReference` (Integration)
3. Validations: unique SKU, unique nullable barcode, unit_type enum
4. Admin-only CRUD policies; consulta read-only
5. API `GET/POST/PATCH /api/v1/warehouse/products` (+ warehouses, categories, locations)
6. Alba serializers
7. Seeds: 2 warehouses, 3 categories, 10 products, 20 locations

### Definition of Done

- [ ] Product CRUD with search by SKU/name/category
- [ ] Unique location per warehouse
- [ ] Model tests + request tests per resource

### PR → merge after auth

---

## Branch 3: `feature/warehouse-stock-core` (Dev B, ~3 days)

**Stories:** US-005, US-041 (partial API)  
**Depends on:** master-data merge  
**Blocks:** all of Phase 1+

### Tasks

1. Migrations: warehouse_sequences, stock_levels, stock_movements
2. Copy/adapt `Warehouse::StockUpdater` (ADR-0001)
3. Models `StockLevel`, `StockMovement`
4. Service `Warehouse::InitialStockImporter` (CSV)
5. `Integration::ProductImporter` stub (ADR-0005)
6. API:
   - `POST /api/v1/warehouse/initial_stock/import`
   - `GET /api/v1/warehouse/stock_movements`
7. **Required tests:**
   - increment/decrement
   - reserve/release
   - concurrency with 2 threads (InsufficientStockError)
   - warehouse_id coherence

### Definition of Done

- [ ] Working initial CSV load
- [ ] Every stock change goes through StockUpdater
- [ ] Audit trail queryable by product_id
- [ ] Code review: zero direct writes to stock_levels outside the service

### PR → merge after master-data

---

## Team synchronization

| Meeting | When | Topic |
|---------|--------|------|
| Kickoff | Day 0 | Review ADR-0001 StockUpdater contract |
| Mid-week | Day 3 | Demo auth + master-data |
| Gate review | Day 5–7 | Merge stock-core; validate concurrency tests |

---

## After Phase 0

| Branch | Stories | Dev |
|------|-----------|-----|
| `feature/warehouse-reception` | US-010, US-011 | B |
| `feature/warehouse-inventory-query` | US-030 | A |

See the full roadmap in `docs/specs/warehouse-mvp.md`.

---

## Risks and mitigation

| Risk | Mitigation |
|--------|------------|
| No Rails repo yet | Create `warehouse-wms` with `rails new` on day 0 |
| Migration timestamp collisions | Rename when copying from examples/ |
| Dev C blocked without auth merge | Use a temporary feature-flag policy in master-data |

---

## References

- Example migrations: `examples/warehouse-wms/db/migrate/`
- StockUpdater example: `examples/warehouse-wms/app/services/warehouse/stock_updater.rb`
- DBA review: `docs/architecture/warehouse-mvp-migrations-review.md`

---

## Versión en español

# Runbook: WMS MVP — Fase 0 Kickoff

**Objetivo:** Arrancar implementación en repositorio Rails con las 3 ramas fundacionales mergeadas en 5–7 días.  
**Audiencia:** 2–3 desarrolladores backend/frontend  
**Prerequisitos:** ADRs 0001–0005 Accepted, DBA review Approved

---

## Checklist previo (día 0)

- [ ] Repositorio Rails creado o identificado (no es este framework repo)
- [ ] MySQL 8 local o Docker disponible
- [ ] Copiar `.ai/` del framework al repo de la app (opcional)
- [ ] Copiar `examples/warehouse-wms/` como base
- [ ] Crear board con 3 ramas Fase 0 asignadas

---

## Rama 1: `feature/warehouse-auth-rbac` (Dev C, ~2 días)

**Historias:** US-040

### Tareas

1. `rails generate devise:install` + `devise User name:string`
2. Migración `AddRoleToUsers` (ver ejemplo)
3. Modelo `User` con `enum :role, { admin: 0, supervisor: 1, operario: 2, consulta: 3 }`
4. `ApplicationController` + `authenticate_user!`
5. Instalar Pundit; `ApplicationPolicy`; policies base
6. Seed: `admin@example.com` / password en credentials
7. Layout mínimo Inertia o ERB con login

### Definition of Done

- [ ] Login/logout funcional
- [ ] 4 roles en DB
- [ ] Request spec: operario no accede a ruta admin

### PR → merge a `main`

---

## Rama 2: `feature/warehouse-master-data` (Dev A, ~3 días)

**Historias:** US-001, US-002, US-003, US-004  
**Depende de:** merge auth (para policies)

### Tareas

1. Migraciones: warehouses, categories, products, locations, external_references
2. Modelos `Warehouse::` namespace (ADR-0004):
   - `Warehouse::Warehouse`, `Category`, `Product`, `Location`
   - `ExternalReference` global (Integration)
3. Validaciones: SKU único, barcode único nullable, unit_type enum
4. Policies CRUD admin-only; consulta read-only
5. API `GET/POST/PATCH /api/v1/warehouse/products` (+ warehouses, categories, locations)
6. Serializers Alba
7. Seeds: 2 almacenes, 3 categorías, 10 productos, 20 ubicaciones

### Definition of Done

- [ ] CRUD productos con búsqueda por SKU/nombre/categoría
- [ ] Ubicación única por almacén
- [ ] Tests modelo + request por recurso

### PR → merge tras auth

---

## Rama 3: `feature/warehouse-stock-core` (Dev B, ~3 días)

**Historias:** US-005, US-041 (API parcial)  
**Depende de:** merge master-data  
**Bloqueante para:** toda Fase 1+

### Tareas

1. Migraciones: warehouse_sequences, stock_levels, stock_movements
2. Copiar/adaptar `Warehouse::StockUpdater` (ADR-0001)
3. Modelos `StockLevel`, `StockMovement`
4. Servicio `Warehouse::InitialStockImporter` (CSV)
5. `Integration::ProductImporter` stub (ADR-0005)
6. API:
   - `POST /api/v1/warehouse/initial_stock/import`
   - `GET /api/v1/warehouse/stock_movements`
7. **Tests obligatorios:**
   - increment/decrement
   - reserve/release
   - concurrencia 2 threads (InsufficientStockError)
   - warehouse_id coherence

### Definition of Done

- [ ] CSV carga inicial funcional
- [ ] Todo cambio de stock vía StockUpdater
- [ ] Auditoría consultable por product_id
- [ ] Code review: cero escrituras directas a stock_levels fuera del servicio

### PR → merge tras master-data

---

## Sincronización equipo

| Reunión | Cuándo | Tema |
|---------|--------|------|
| Kickoff | Día 0 | Repaso ADR-0001 contrato StockUpdater |
| Mid-week | Día 3 | Demo auth + master-data |
| Gate review | Día 5–7 | Merge stock-core; validar tests concurrencia |

---

## Después de Fase 0

| Rama | Historias | Dev |
|------|-----------|-----|
| `feature/warehouse-reception` | US-010, US-011 | B |
| `feature/warehouse-inventory-query` | US-030 | A |

Ver roadmap completo en `docs/specs/warehouse-mvp.md`.

---

## Riesgos y mitigación

| Riesgo | Mitigación |
|--------|------------|
| No hay repo Rails aún | Crear `warehouse-wms` con `rails new` día 0 |
| Colisión timestamps migraciones | Renombrar al copiar desde examples/ |
| Dev C bloqueado sin merge auth | Usar feature flag policies temporales en master-data |

---

## Referencias

- Migraciones ejemplo: `examples/warehouse-wms/db/migrate/`
- StockUpdater ejemplo: `examples/warehouse-wms/app/services/warehouse/stock_updater.rb`
- DBA review: `docs/architecture/warehouse-mvp-migrations-review.md`
