> Language: English | [Español](#versión-en-español)

# ADR-0004: Module boundaries and Rails structure of the WMS

## Status

Accepted

## Date

2026-06-16

## Context

The MVP covers 18 P0 stories with a bounded but non-trivial domain: catalog, operations, approvals, and audit. The target repository will follow the Rails + MySQL + React/Inertia stack (`.ai/standards/development.md`). We need a folder structure that lets 2–3 developers work in parallel without collisions or circular coupling.

## Decision

Isolate the WMS domain under the **`Warehouse::`** namespace with the following structure:

```
app/
  models/warehouse/
    product.rb              # Warehouse::Product
    stock_level.rb
    stock_movement.rb
    reception_order.rb
    ...
  services/warehouse/
    stock_updater.rb
    outbound/
      start_picking.rb
      availability_checker.rb
    picking/
      generate_lines.rb
      location_allocator.rb
      confirm_line.rb
    reception/
      confirm_line.rb
    adjustments/
      approve.rb
    ...
  policies/warehouse/
    product_policy.rb
    ...
  controllers/warehouse/
    ...
  serializers/warehouse/     # o Alba/Blueprinter según ADR futuro de API
integration/                 # SIN namespace Warehouse — cross-cutting
  base_importer.rb           # Integration::BaseImporter
  product_importer.rb
  import_result.rb
```

### Conventions

| Aspect | Decision |
|---------|----------|
| DB tables | `warehouse_` prefix optionally **not** used; domain names (`products`, `stock_levels`) with namespace in code |
| States | `enum` with `_suffix` or `_prefix`: `enum :status, { draft: 0, ... }, suffix: true` |
| Authorization | Pundit; one policy per resource in `app/policies/warehouse/` |
| API | `/api/v1/warehouse/...` — versioned from the start |
| Inertia UI | `app/frontend/pages/warehouse/` |
| Jobs | `Warehouse::ImportStockJob` in `app/jobs/warehouse/` |
| Order numbers | `Warehouse::DocumentNumberGenerator` service with a pessimistic lock on the `warehouse_sequences` table |

### `warehouse_sequences` table

| Field | Use |
|-------|-----|
| `prefix` | `REC`, `OUT`, `TRF` |
| `year` | 2026 |
| `last_value` | Incremental counter |

Generates `REC-2026-00001` without collisions.

### What stays outside the namespace

- `User` / Devise authentication (global model)
- `ExternalReference` / `Integration::*` (cross-cutting layer for ERP)

## Alternatives Considered

| Option | Pros | Cons |
|--------|------|------|
| **A: Warehouse:: namespace (chosen)** | Clear boundaries; parallel work; ready for a future engine | More verbose in routes and files |
| **B: Internal Rails Engine gem** | Strong isolation | Mount/engine overhead for an MVP |
| **C: No namespace, prefixes in tables** | Fewer folders | Collision with future business models (CRM, billing) |

## Consequences

### Positive

- Roadmap branches map to subfolders (`services/warehouse/reception/`, etc.).
- Possible extraction into an engine in v2 without renaming tables.

### Negative

- Extra configuration: `config.autoload_paths`, inflections if applicable.
- All devs must respect the namespace; code review is mandatory.

## Compliance

- Standards: `.ai/standards/development.md`, `.ai/standards/documentation.md`
- Stories blocked until Accepted: all (cross-cutting structure)
- Depends on: none

---

## Versión en español

# ADR-0004: Límites de módulo y estructura Rails del WMS

## Status

Accepted

## Date

2026-06-16

## Context

El MVP abarca 18 historias P0 con dominio acotado pero no trivial: catálogo, operaciones, aprobaciones y auditoría. El repositorio objetivo seguirá stack Rails + MySQL + React/Inertia (`.ai/standards/development.md`). Se necesita estructura de carpetas que permita trabajo paralelo de 2–3 desarrolladores sin colisiones ni acoplamiento circular.

## Decision

Aislar el dominio WMS bajo el namespace **`Warehouse::`** con la siguiente estructura:

```
app/
  models/warehouse/
    product.rb              # Warehouse::Product
    stock_level.rb
    stock_movement.rb
    reception_order.rb
    ...
  services/warehouse/
    stock_updater.rb
    outbound/
      start_picking.rb
      availability_checker.rb
    picking/
      generate_lines.rb
      location_allocator.rb
      confirm_line.rb
    reception/
      confirm_line.rb
    adjustments/
      approve.rb
    ...
  policies/warehouse/
    product_policy.rb
    ...
  controllers/warehouse/
    ...
  serializers/warehouse/     # o Alba/Blueprinter según ADR futuro de API
integration/                 # SIN namespace Warehouse — cross-cutting
  base_importer.rb           # Integration::BaseImporter
  product_importer.rb
  import_result.rb
```

### Convenciones

| Aspecto | Decisión |
|---------|----------|
| Tablas DB | Prefijo `warehouse_` opcional **no** usado; nombres de dominio (`products`, `stock_levels`) con namespace en código |
| Estados | `enum` con `_suffix` o `_prefix`: `enum :status, { draft: 0, ... }, suffix: true` |
| Autorización | Pundit; una policy por recurso en `app/policies/warehouse/` |
| API | `/api/v1/warehouse/...` — versionada desde el inicio |
| UI Inertia | `app/frontend/pages/warehouse/` |
| Jobs | `Warehouse::ImportStockJob` en `app/jobs/warehouse/` |
| Números de orden | Servicio `Warehouse::DocumentNumberGenerator` con lock pesimista en tabla `warehouse_sequences` |

### Tabla `warehouse_sequences`

| Campo | Uso |
|-------|-----|
| `prefix` | `REC`, `OUT`, `TRF` |
| `year` | 2026 |
| `last_value` | Contador incremental |

Genera `REC-2026-00001` sin colisiones.

### Lo que queda fuera del namespace

- `User` / autenticación Devise (modelo global)
- `ExternalReference` / `Integration::*` (capa transversal para ERP)

## Alternatives Considered

| Option | Pros | Cons |
|--------|------|------|
| **A: Namespace Warehouse:: (elegida)** | Límites claros; trabajo paralelo; preparado para engine futuro | Más verboso en rutas y archivos |
| **B: Rails Engine gem interna** | Aislamiento fuerte | Overhead de mount/engine para MVP |
| **C: Sin namespace, prefijos en tablas** | Menos carpetas | Colisión con modelos de negocio futuro (CRM, facturación) |

## Consequences

### Positive

- Ramas del roadmap mapean a subcarpetas (`services/warehouse/reception/`, etc.).
- Posible extracción a engine en v2 sin renombrar tablas.

### Negative

- Configuración extra: `config.autoload_paths`, inflections si aplica.
- Todos los devs deben respetar namespace; code review obligatorio.

## Compliance

- Standards: `.ai/standards/development.md`, `.ai/standards/documentation.md`
- Stories blocked until Accepted: todas (estructura transversal)
- Depends on: ninguno
