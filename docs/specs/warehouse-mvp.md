> Language: English | [Español](#versión-en-español)

# Feature: WMS MVP — Multi-Warehouse Distribution

**Status:** Approved  
**Author:** Product Owner  
**Date:** 2026-06-16  
**Stakeholders:** Sales leadership, Warehouse operations, IT  
**Spec ID:** `warehouse-mvp`

---

## Problem Statement

A distribution/wholesale company operates several warehouses with fragmented inventory control (spreadsheets, manual records). There is no unified stock visibility, movements are not auditable, and discrepancies are detected late. A minimum viable WMS is needed to centralize multi-warehouse inventory without depending on ERP integration yet.

## Business Context

- **Sector:** Distribution / wholesale of physical products.
- **Operation:** Multiple warehouses (sites or distribution centers), supplier receiving, customer order picking, inter-warehouse transfers.
- **v1:** Greenfield start; no ERP integration. Architecture ready for future importers/services.

---

## Closed Decisions

| # | Topic | Decision |
|---|------|----------|
| D1 | ERP | Greenfield start. No ERP in v1. Prepare the integration layer (`Integration::*`, external references, importers). |
| D2 | Barcode | Not mandatory. Search by SKU, name, and category. Optional `barcode` field on products. |
| D3 | Units | Fixed enum: `unidad`, `caja`, `paquete`, `kg`, `litro`. No automatic conversions in v1. Model extensible for future conversions. |
| D4 | Approvals | Normal outbound shipments need no approval. Supervisor approval IS required for: manual adjustments, stock corrections (counting), and cancellations of confirmed movements. |
| D5 | Geographic scope | Multi-warehouse included in the MVP (warehouse management, stock per warehouse, transfers). |
| D6 | Future integration | Importer pattern + polymorphic `external_references`; do not couple domain logic to an ERP. |

---

## Goals

| ID | Goal | Success metric (90 days post go-live) |
|----|----------|------------------------------------------|
| G1 | Multi-warehouse stock visibility | Availability lookup by product/warehouse in < 3 s; 0 operational spreadsheets |
| G2 | Movement traceability | 100% of inbound, outbound, transfers, and approved adjustments are audited |
| G3 | Reduce operational errors | −40% picking discrepancies vs manual baseline |
| G4 | Correction control | 100% of adjustments and cancellations go through an approval flow |
| G5 | Foundation for ERP integration | Importer contract documented; at least one `ProductImporter` stub implementable without refactor |

## Non-Goals (out of MVP)

- Real-time integration with an external ERP
- Automatic conversions between units of measure
- Mandatory barcode or dedicated scanning hardware
- Native mobile app
- Lots, serials, expiration (FEFO/FIFO)
- Picking route optimization
- Billing, purchasing, CRM
- Cross-docking, waves, kitting
- ZPL label printing
- Automatic reservations from e-commerce
- Granular permissions per warehouse zone
- Multi-language

---

## Users and roles

| Role | Description | Key permissions |
|-----|-------------|----------------|
| **admin** | System configuration | CRUD catalog, warehouses, locations, users; view everything |
| **supervisor** | Operational control | Approve adjustments, corrections, and cancellations; counts; reports |
| **operario** | Floor execution | Receiving, picking, transfers, request adjustments/cancellations |
| **consulta** | Read-only | Query stock and history; no changes |

---

## MVP Modules

```mermaid
flowchart TB
    subgraph master [Datos maestros]
        WH[Almacenes]
        CAT[Categorías]
        PRD[Productos]
        LOC[Ubicaciones]
    end

    subgraph ops [Operaciones]
        REC[Recepción]
        OUT[Salidas / Picking]
        TRF[Transferencias]
        CNT[Conteo]
    end

    subgraph control [Control]
        ADJ[Ajustes y aprobaciones]
        CAN[Cancelaciones]
        AUD[Auditoría]
    end

    subgraph future [Preparado v2]
        INT[Integration::Importers]
    end

    WH --> LOC
    CAT --> PRD
    PRD --> REC
    PRD --> OUT
    LOC --> REC
    LOC --> OUT
    REC --> AUD
    OUT --> AUD
    TRF --> AUD
    CNT --> ADJ
    ADJ --> AUD
    CAN --> AUD
    INT -.-> PRD
```

| Module | Responsibility |
|--------|-----------------|
| Warehouses | CRUD of active/inactive warehouses |
| Catalog | Categories and products (SKU, name, category, unit, optional barcode) |
| Locations | Hierarchy per warehouse: aisle → rack → position |
| Inventory | Stock by product + location + warehouse; available vs reserved |
| Receiving | Order → confirmation → stock increase |
| Outbound | Order → picking → confirmation → stock decrease |
| Transfers | Inter-warehouse shipping with states draft → in transit → received |
| Counting and adjustments | Physical count; correction request; supervisor approval |
| Cancellations | Request and approval to reverse a confirmed movement |
| Users | Authentication and basic RBAC |
| Auditing | Immutable `StockMovement` for every stock change |
| Integration (stub) | Importer interface; polymorphic `ExternalReference` |

---

## P0 Stories (index)

| ID | Title | Dependencies |
|----|--------|--------------|
| [US-001](../stories/warehouse-mvp/US-001.md) | Category management | — |
| [US-002](../stories/warehouse-mvp/US-002.md) | Product management | US-001 |
| [US-003](../stories/warehouse-mvp/US-003.md) | Warehouse management | — |
| [US-004](../stories/warehouse-mvp/US-004.md) | Location management | US-003 |
| [US-005](../stories/warehouse-mvp/US-005.md) | Initial stock load | US-002, US-004 |
| [US-010](../stories/warehouse-mvp/US-010.md) | Create reception order | US-002, US-003 |
| [US-011](../stories/warehouse-mvp/US-011.md) | Confirm reception | US-010, US-005 |
| [US-020](../stories/warehouse-mvp/US-020.md) | Create outbound order | US-002, US-003 |
| [US-021](../stories/warehouse-mvp/US-021.md) | Picking list | US-020 |
| [US-022](../stories/warehouse-mvp/US-022.md) | Confirm picking | US-021 |
| [US-023](../stories/warehouse-mvp/US-023.md) | Insufficient stock alert | US-020 |
| [US-030](../stories/warehouse-mvp/US-030.md) | Multi-warehouse inventory lookup | US-005 |
| [US-031](../stories/warehouse-mvp/US-031.md) | Inventory count | US-005 |
| [US-032](../stories/warehouse-mvp/US-032.md) | Request stock adjustment or correction | US-031 |
| [US-033](../stories/warehouse-mvp/US-033.md) | Approve or reject adjustments | US-032 |
| [US-034](../stories/warehouse-mvp/US-034.md) | Inter-warehouse transfer | US-005 |
| [US-035](../stories/warehouse-mvp/US-035.md) | Cancel a confirmed movement | US-011, US-022 |
| [US-040](../stories/warehouse-mvp/US-040.md) | User and role management | — |
| [US-041](../stories/warehouse-mvp/US-041.md) | Movement history | US-005 |

---

## Initial data model

### Entity-relationship diagram (conceptual)

```mermaid
erDiagram
    Warehouse ||--o{ Location : has
    Warehouse ||--o{ StockLevel : holds
    Category ||--o{ Product : classifies
    Product ||--o{ StockLevel : tracked_in
    Location ||--o{ StockLevel : at
    Product ||--o{ ReceptionLine : receives
    Product ||--o{ OutboundLine : ships
    ReceptionOrder ||--|{ ReceptionLine : contains
    OutboundOrder ||--|{ OutboundLine : contains
    OutboundLine ||--o| PickingLine : picked_via
    Warehouse ||--o{ ReceptionOrder : receives_at
    Warehouse ||--o{ OutboundOrder : ships_from
    TransferOrder ||--|{ TransferLine : contains
    Warehouse ||--o{ TransferOrder : origin_dest
    InventoryCount ||--|{ InventoryCountLine : contains
    InventoryAdjustment ||--|{ InventoryAdjustmentLine : contains
    StockMovement }o--|| Product : affects
    StockMovement }o--o| User : performed_by
    ExternalReference }o--o| Product : links
    MovementCancellation }o--|| StockMovement : reverses
```

### Key entities and attributes

#### `warehouses`
| Field | Type | Notes |
|-------|------|-------|
| id | PK | |
| code | string, unique | E.g. `CD-MAD`, `CD-BCN` |
| name | string | |
| address | text, optional | |
| active | boolean | Inactive: no new operations |
| timestamps | | |

#### `categories`
| Field | Type | Notes |
|-------|------|-------|
| id | PK | |
| name | string, unique | |
| parent_id | FK optional | Simple hierarchy (1 level in MVP) |
| active | boolean | |
| timestamps | | |

#### `products`
| Field | Type | Notes |
|-------|------|-------|
| id | PK | |
| sku | string, unique | |
| name | string | |
| category_id | FK | |
| unit_type | enum | `unidad`, `caja`, `paquete`, `kg`, `litro` |
| barcode | string, nullable, unique | Optional in v1 |
| min_stock_level | decimal, optional | P1 alert; field present, P1 logic |
| active | boolean | |
| timestamps | | |

> **Unit extensibility (v2):** `unit_conversions` table (`product_id`, `from_unit`, `to_unit`, `factor`) unused in v1.

#### `locations`
| Field | Type | Notes |
|-------|------|-------|
| id | PK | |
| warehouse_id | FK | |
| code | string | Unique per warehouse. E.g. `A-01-03` |
| aisle | string | |
| rack | string | |
| position | string | |
| active | boolean | |
| timestamps | | |

**Unique index:** `(warehouse_id, code)`

#### `stock_levels`
| Field | Type | Notes |
|-------|------|-------|
| id | PK | |
| product_id | FK | |
| location_id | FK | |
| warehouse_id | FK | Denormalized for queries |
| quantity_on_hand | decimal(15,3) | Physical at the location |
| quantity_reserved | decimal(15,3) | Reserved by in-progress outbound |
| timestamps | | |

**Unique index:** `(product_id, location_id)`  
**Available:** `quantity_on_hand - quantity_reserved` (computed, not persisted)

#### `stock_movements` (immutable audit)
| Field | Type | Notes |
|-------|------|-------|
| id | PK | |
| product_id | FK | |
| warehouse_id | FK | |
| location_id | FK, nullable | Null in aggregated transfers |
| movement_type | enum | `reception`, `outbound`, `transfer_out`, `transfer_in`, `adjustment`, `cancellation` |
| quantity | decimal | Positive inbound, negative outbound |
| quantity_before | decimal | |
| quantity_after | decimal | |
| reference_type | string | Polymorphic: `ReceptionLine`, `PickingLine`, etc. |
| reference_id | bigint | |
| user_id | FK | |
| notes | text, optional | |
| occurred_at | datetime | |
| cancelled_at | datetime, nullable | If reversed |
| timestamps | | |

#### `reception_orders` / `reception_lines`
- **Order:** `warehouse_id`, `supplier_name`, `reference_number`, `status` (`draft`, `partial`, `completed`, `cancelled`), `received_by`, timestamps
- **Line:** `reception_order_id`, `product_id`, `expected_quantity`, `received_quantity`, `location_id` (on confirmation), `status`

#### `outbound_orders` / `outbound_lines` / `picking_lines`
- **Order:** `warehouse_id`, `customer_name`, `reference_number`, `status` (`draft`, `picking`, `partial`, `completed`, `cancelled`)
- **Line:** `product_id`, `requested_quantity`, `picked_quantity`, `status`
- **PickingLine:** `outbound_line_id`, `location_id`, `quantity_to_pick`, `quantity_picked`, `sequence` (order by location)

#### `transfer_orders` / `transfer_lines`
- **Order:** `origin_warehouse_id`, `destination_warehouse_id`, `status` (`draft`, `in_transit`, `partial`, `completed`, `cancelled`), `shipped_at`, `received_at`
- **Line:** `product_id`, `requested_quantity`, `shipped_quantity`, `received_quantity`

**Rule:** On shipping (`in_transit`), stock is deducted at the origin. On receiving at the destination, it is added at the destination warehouse's receiving location.

#### `inventory_counts` / `inventory_count_lines`
- **Count:** `warehouse_id`, `status` (`in_progress`, `submitted`, `closed`), `started_by`, `submitted_at`
- **Line:** `product_id`, `location_id`, `system_quantity`, `counted_quantity`, `variance`

#### `inventory_adjustments` / `inventory_adjustment_lines`
- **Adjustment:** `source_type` (`manual`, `count`), `inventory_count_id` nullable, `status` (`pending`, `approved`, `rejected`), `requested_by`, `approved_by`, `reason`, timestamps
- **Line:** `product_id`, `location_id`, `quantity_before`, `quantity_change`, `quantity_after`

#### `movement_cancellations`
| Field | Type | Notes |
|-------|------|-------|
| stock_movement_id | FK | Movement to reverse |
| status | enum | `pending`, `approved`, `rejected` |
| requested_by | FK | |
| approved_by | FK, nullable | |
| reason | text | Required |
| reversal_movement_id | FK, nullable | Compensating movement on approval |

#### `external_references` (ERP preparation)
| Field | Type | Notes |
|-------|------|-------|
| referable_type | string | `Product`, `Warehouse`, etc. |
| referable_id | bigint | |
| source_system | string | E.g. `erp` |
| external_id | string | ID in the external system |
| last_synced_at | datetime, nullable | |

**Unique index:** `(source_system, external_id, referable_type)`

#### `users` / roles
- Role stored as an enum in `users.role`: `admin`, `supervisor`, `operario`, `consulta`
- Authentication: per the project stack (Devise or equivalent)

### Domain services (preliminary)

| Service | Responsibility |
|----------|-----------------|
| `StockUpdater` | Single mutation point for `stock_levels`; always creates a `stock_movement` |
| `ReservationService` | Reserves/releases stock when creating a picking |
| `AdjustmentWorkflow` | Request → approval → application via `StockUpdater` |
| `CancellationWorkflow` | Request → approval → compensating movement |
| `Integration::ProductImporter` | Interface: `#import(row)` → `Product`; stub implementation in v1 |
| `Integration::ImportResult` | Value object: `success`, `errors`, `record` |

---

## Cross-cutting business rules

1. **Unique SKU** at the system level; **unique location code** per warehouse.
2. **Unique barcode** when present (can be null).
3. **Stock never negative** in `quantity_on_hand` nor in available (`on_hand - reserved`).
4. **Stock mutation** only through `StockUpdater` (transactional service).
5. **Audited movements** are append-only; corrections via a compensating movement or an approved cancellation.
6. **Normal outbound** does not require supervisor approval.
7. **Adjustments, count corrections, and cancellations** require approval from `supervisor` or `admin`.
8. **Inactive warehouse:** no new receptions, outbound, or transfers; querying allowed.
9. **Inactive product:** does not appear in new orders; existing stock remains visible.
10. **Transfer:** stock leaves the origin when marked `in_transit`; enters the destination when the transfer reception is confirmed.
11. **No unit conversions:** quantities always in the product's unit.

---

## MVP-ready criteria

The company can operate for **2 weeks** with at least **2 active warehouses**:

- Daily receptions and outbound without Excel
- At least 1 completed inter-warehouse transfer
- 1 count cycle with an approved adjustment
- 1 approved movement cancellation
- Consolidated and per-warehouse stock lookup
- Audit queryable by product

---

## Implementation roadmap by branch

Designed for **2–3 developers** working in parallel with frequent merges to `main` (or `develop`). Each branch is a mergeable vertical slice with feature flags if applicable.

### Conventions

- Branch prefix: `feature/warehouse-<slice>`
- Each branch includes: migrations, models, services, minimal API/UI, slice tests
- **Do not start slice N+1** until slice N's migrations are in the base branch

### Phase 0 — Foundation (Week 1)

| Branch | Suggested owner | Deliverables | Stories |
|------|----------------|-------------|-----------|
| `feature/warehouse-auth-rbac` | Dev C | Users, roles, Pundit/CanCan policies, base layout | US-040 |
| `feature/warehouse-master-data` | Dev A | Warehouses, categories, products, locations, `ExternalReference` stub | US-001, US-002, US-003, US-004 |
| `feature/warehouse-stock-core` | Dev B | `stock_levels`, `stock_movements`, `StockUpdater`, initial CSV load | US-005, US-041 (partial) |

**Merge order:** auth → master-data → stock-core

```mermaid
gantt
    title Roadmap MVP WMS (6-8 semanas)
    dateFormat YYYY-MM-DD
    section Fase0
    auth-rbac           :a1, 2026-06-17, 5d
    master-data         :a2, 2026-06-17, 7d
    stock-core          :a3, after a2, 5d
    section Fase1
    reception           :b1, after a3, 7d
    inventory-query     :b2, after a3, 4d
    section Fase2
    outbound-picking    :c1, after b1, 10d
    section Fase3
    count-adjustments   :d1, after c1, 7d
    transfers           :d2, after b1, 7d
    cancellations       :d3, after d1, 5d
```

### Phase 1 — Inbound and lookup (Week 2–3)

| Branch | Owner | Deliverables | Stories |
|------|-------|-------------|-----------|
| `feature/warehouse-reception` | Dev B | Reception orders, confirmation, `StockUpdater` integration | US-010, US-011 |
| `feature/warehouse-inventory-query` | Dev A | Search by SKU/name/category, multi-warehouse filters | US-030 |

**Parallel:** Dev B receiving + Dev A lookup (both depend on stock-core).

### Phase 2 — Outbound (Week 3–5)

| Branch | Owner | Deliverables | Stories |
|------|-------|-------------|-----------|
| `feature/warehouse-outbound` | Dev C | Outbound orders, reservations, stock alerts | US-020, US-023 |
| `feature/warehouse-picking` | Dev C | Picking list, confirmation, stock decrease | US-021, US-022 |

**Sequential within team C:** outbound → picking (same branch or sub-branches).

### Phase 3 — Control and transfers (Week 5–7)

| Branch | Owner | Deliverables | Stories |
|------|-------|-------------|-----------|
| `feature/warehouse-transfers` | Dev A | Transfer orders, in_transit, destination receiving | US-034 |
| `feature/warehouse-counts` | Dev B | Counting, correction request | US-031, US-032 |
| `feature/warehouse-adjustments-approval` | Dev B | Adjustment approval flow | US-033 |
| `feature/warehouse-cancellations` | Dev C | Cancellation of confirmed movements | US-035 |

**Parallel:** transfers (A) + counts/adjustments (B) + cancellations (C) after picking is merged.

### Phase 4 — Integration stub and hardening (Week 7–8)

| Branch | Owner | Deliverables |
|------|-------|-------------|
| `feature/warehouse-integration-stub` | Dev A | `Integration::ProductImporter`, integration README, contract tests |
| `feature/warehouse-audit-ui` | Dev C | US-041 full UI, movements CSV export |
| `fix/warehouse-e2e-hardening` | Everyone | E2E tests for critical flows, bug fixes |

### Suggested assignment per developer

| Dev | Main focus | Branches |
|-----|----------------|-------|
| **Dev A** | Master data, queries, transfers, integration | master-data, inventory-query, transfers, integration-stub |
| **Dev B** | Stock core, receiving, counts and approvals | stock-core, reception, counts, adjustments-approval |
| **Dev C** | Auth, outbound, picking, cancellations, audit UI | auth-rbac, outbound, picking, cancellations, audit-ui |

### Sync points (daily / twice-weekly)

1. **`StockUpdater` contract** — blocking for reception, picking, transfers, adjustments
2. **Order states** — shared enum documented before outbound
3. **Authorization policies** — role × action matrix before approvals

---

## ERP integration preparation (v2)

```
app/
  services/
    integration/
      base_importer.rb       # interface común
      product_importer.rb    # stub v1; implementación ERP v2
      import_result.rb
  models/
    external_reference.rb
```

**`ProductImporter#import(row)` contract:**
- Input: `{ sku:, name:, category_name:, unit_type:, barcode: nil, external_id: }`
- Output: `ImportResult` with the created/updated product or validation errors
- Idempotent by `external_id` + `source_system: 'erp'`

---

## Technical Considerations

- Target stack: Rails + MySQL + React/Inertia (per project standards)
- DB transactions in all stock flows
- **ADR-0001:** `Warehouse::StockUpdater` as the single inventory writer — [Accepted](../architecture/adr-0001-stock-updater-single-writer.md)
- **ADR-0002:** Location-level reservations when starting picking — [Accepted](../architecture/adr-0002-outbound-stock-reservations.md)
- **ADR-0003:** Greedy allocation by location order — [Accepted](../architecture/adr-0003-picking-location-allocation.md)
- **ADR-0004:** `Warehouse::` namespace and module structure — [Accepted](../architecture/adr-0004-warehouse-module-boundaries.md)
- **ADR-0005:** `Integration::*` layer for a future ERP — [Accepted](../architecture/adr-0005-erp-integration-layer.md)
- Technical design: [warehouse-mvp.md](../design/warehouse-mvp.md)
- Architecture review: [warehouse-mvp-review.md](../architecture/warehouse-mvp-review.md) — **APPROVED WITH CONDITIONS**
- Performance: indexes on `stock_levels(warehouse_id, product_id)`, `stock_movements(product_id, occurred_at)`
- Security: RBAC in API and UI; non-editable auditing

## Dependencies

- No external integration in v1
- Infrastructure per `.ai/standards/aws-infrastructure.md` once a deployed app exists

## Open Questions

- [ ] Is the supplier modeled as an entity or a text field in receiving? → **MVP: text field `supplier_name`**
- [ ] Customer in outbound: entity or text? → **MVP: text field `customer_name`**
- [ ] Warehouse limit in v1? → **No technical limit; expected operation: 2–10**

## Approval

- [x] Product Owner sign-off
- [x] Rails Architect review — APPROVED WITH CONDITIONS (2026-06-16)
- [x] MySQL DBA review — APPROVED WITH CONDITIONS (2026-06-16) — [migrations review](../architecture/warehouse-mvp-migrations-review.md)

---

## Versión en español

# Feature: WMS MVP — Distribución Multi-Almacén

**Status:** Approved  
**Author:** Product Owner  
**Date:** 2026-06-16  
**Stakeholders:** Dirección comercial, Operaciones de almacén, IT  
**Spec ID:** `warehouse-mvp`

---

## Problem Statement

Una empresa distribuidora/comercializadora opera varios almacenes con control de inventario fragmentado (hojas de cálculo, registros manuales). No hay visibilidad unificada del stock, los movimientos no son auditables y las discrepancias se detectan tarde. Se necesita un WMS mínimo viable que centralice inventario multi-almacén sin depender aún de integración con ERP.

## Contexto de negocio

- **Sector:** Distribución / comercialización de productos físicos.
- **Operación:** Múltiples almacenes (sedes o centros de distribución), recepción de proveedores, preparación de pedidos de clientes, transferencias entre almacenes.
- **v1:** Arranque en blanco; sin integración ERP. Arquitectura preparada para importadores/servicios futuros.

---

## Decisiones cerradas

| # | Tema | Decisión |
|---|------|----------|
| D1 | ERP | Arranque en blanco. Sin ERP en v1. Preparar capa de integración (`Integration::*`, referencias externas, importadores). |
| D2 | Código de barras | No obligatorio. Búsqueda por SKU, nombre y categoría. Campo `barcode` opcional en productos. |
| D3 | Unidades | Enum fijo: `unidad`, `caja`, `paquete`, `kg`, `litro`. Sin conversiones automáticas en v1. Modelo extensible para conversiones futuras. |
| D4 | Aprobaciones | Salidas normales sin aprobación. Sí requieren aprobación de supervisor: ajustes manuales, correcciones de stock (conteo) y cancelaciones de movimientos confirmados. |
| D5 | Alcance geográfico | Multi-almacén incluido en MVP (gestión de almacenes, stock por almacén, transferencias). |
| D6 | Integración futura | Patrón importer + `external_references` polimórficas; sin acoplar lógica de dominio a un ERP. |

---

## Goals

| ID | Objetivo | Métrica de éxito (90 días post go-live) |
|----|----------|------------------------------------------|
| G1 | Visibilidad de stock multi-almacén | Consulta de disponibilidad por producto/almacén en < 3 s; 0 hojas de cálculo operativas |
| G2 | Trazabilidad de movimientos | 100 % de entradas, salidas, transferencias y ajustes aprobados quedan en auditoría |
| G3 | Reducir errores operativos | −40 % discrepancias en picking vs baseline manual |
| G4 | Control de correcciones | 100 % de ajustes y cancelaciones pasan por flujo de aprobación |
| G5 | Base para integración ERP | Contrato de importador documentado; al menos un stub de `ProductImporter` implementable sin refactor |

## Non-Goals (fuera de MVP)

- Integración en tiempo real con un ERP externo
- Conversiones automáticas entre unidades de medida
- Código de barras obligatorio o hardware de escaneo dedicado
- App móvil nativa
- Lotes, series, caducidad (FEFO/FIFO)
- Optimización de rutas de picking
- Facturación, compras, CRM
- Cross-docking, ondas, kitting
- Impresión de etiquetas ZPL
- Reservas automáticas desde e-commerce
- Permisos granulares por zona de almacén
- Multi-idioma

---

## Usuarios y roles

| Rol | Descripción | Permisos clave |
|-----|-------------|----------------|
| **admin** | Configuración del sistema | CRUD catálogo, almacenes, ubicaciones, usuarios; ver todo |
| **supervisor** | Control operativo | Aprobar ajustes, correcciones y cancelaciones; conteos; reportes |
| **operario** | Ejecución en piso | Recepción, picking, transferencias, solicitar ajustes/cancelaciones |
| **consulta** | Solo lectura | Consultar stock e historial; sin modificar |

---

## Módulos MVP

```mermaid
flowchart TB
    subgraph master [Datos maestros]
        WH[Almacenes]
        CAT[Categorías]
        PRD[Productos]
        LOC[Ubicaciones]
    end

    subgraph ops [Operaciones]
        REC[Recepción]
        OUT[Salidas / Picking]
        TRF[Transferencias]
        CNT[Conteo]
    end

    subgraph control [Control]
        ADJ[Ajustes y aprobaciones]
        CAN[Cancelaciones]
        AUD[Auditoría]
    end

    subgraph future [Preparado v2]
        INT[Integration::Importers]
    end

    WH --> LOC
    CAT --> PRD
    PRD --> REC
    PRD --> OUT
    LOC --> REC
    LOC --> OUT
    REC --> AUD
    OUT --> AUD
    TRF --> AUD
    CNT --> ADJ
    ADJ --> AUD
    CAN --> AUD
    INT -.-> PRD
```

| Módulo | Responsabilidad |
|--------|-----------------|
| Almacenes | CRUD de almacenes activos/inactivos |
| Catálogo | Categorías y productos (SKU, nombre, categoría, unidad, barcode opcional) |
| Ubicaciones | Jerarquía por almacén: pasillo → estante → posición |
| Inventario | Stock por producto + ubicación + almacén; disponible vs reservado |
| Recepción | Orden → confirmación → incremento de stock |
| Salidas | Orden → picking → confirmación → decremento de stock |
| Transferencias | Envío entre almacenes con estados borrador → en tránsito → recibido |
| Conteo y ajustes | Conteo físico; solicitud de corrección; aprobación supervisor |
| Cancelaciones | Solicitud y aprobación para revertir movimiento confirmado |
| Usuarios | Autenticación y RBAC básico |
| Auditoría | `StockMovement` inmutable por cada cambio de stock |
| Integración (stub) | Interfaz importador; `ExternalReference` polimórfico |

---

## Historias P0 (índice)

| ID | Título | Dependencias |
|----|--------|--------------|
| [US-001](../stories/warehouse-mvp/US-001.md) | Gestión de categorías | — |
| [US-002](../stories/warehouse-mvp/US-002.md) | Gestión de productos | US-001 |
| [US-003](../stories/warehouse-mvp/US-003.md) | Gestión de almacenes | — |
| [US-004](../stories/warehouse-mvp/US-004.md) | Gestión de ubicaciones | US-003 |
| [US-005](../stories/warehouse-mvp/US-005.md) | Carga de stock inicial | US-002, US-004 |
| [US-010](../stories/warehouse-mvp/US-010.md) | Crear orden de recepción | US-002, US-003 |
| [US-011](../stories/warehouse-mvp/US-011.md) | Confirmar recepción | US-010, US-005 |
| [US-020](../stories/warehouse-mvp/US-020.md) | Crear orden de salida | US-002, US-003 |
| [US-021](../stories/warehouse-mvp/US-021.md) | Lista de picking | US-020 |
| [US-022](../stories/warehouse-mvp/US-022.md) | Confirmar picking | US-021 |
| [US-023](../stories/warehouse-mvp/US-023.md) | Alerta de stock insuficiente | US-020 |
| [US-030](../stories/warehouse-mvp/US-030.md) | Consulta de inventario multi-almacén | US-005 |
| [US-031](../stories/warehouse-mvp/US-031.md) | Conteo de inventario | US-005 |
| [US-032](../stories/warehouse-mvp/US-032.md) | Solicitar ajuste o corrección de stock | US-031 |
| [US-033](../stories/warehouse-mvp/US-033.md) | Aprobar o rechazar ajustes | US-032 |
| [US-034](../stories/warehouse-mvp/US-034.md) | Transferencia entre almacenes | US-005 |
| [US-035](../stories/warehouse-mvp/US-035.md) | Cancelar movimiento confirmado | US-011, US-022 |
| [US-040](../stories/warehouse-mvp/US-040.md) | Gestión de usuarios y roles | — |
| [US-041](../stories/warehouse-mvp/US-041.md) | Historial de movimientos | US-005 |

---

## Modelo inicial de datos

### Diagrama entidad-relación (conceptual)

```mermaid
erDiagram
    Warehouse ||--o{ Location : has
    Warehouse ||--o{ StockLevel : holds
    Category ||--o{ Product : classifies
    Product ||--o{ StockLevel : tracked_in
    Location ||--o{ StockLevel : at
    Product ||--o{ ReceptionLine : receives
    Product ||--o{ OutboundLine : ships
    ReceptionOrder ||--|{ ReceptionLine : contains
    OutboundOrder ||--|{ OutboundLine : contains
    OutboundLine ||--o| PickingLine : picked_via
    Warehouse ||--o{ ReceptionOrder : receives_at
    Warehouse ||--o{ OutboundOrder : ships_from
    TransferOrder ||--|{ TransferLine : contains
    Warehouse ||--o{ TransferOrder : origin_dest
    InventoryCount ||--|{ InventoryCountLine : contains
    InventoryAdjustment ||--|{ InventoryAdjustmentLine : contains
    StockMovement }o--|| Product : affects
    StockMovement }o--o| User : performed_by
    ExternalReference }o--o| Product : links
    MovementCancellation }o--|| StockMovement : reverses
```

### Entidades y atributos clave

#### `warehouses`
| Campo | Tipo | Notas |
|-------|------|-------|
| id | PK | |
| code | string, unique | Ej. `CD-MAD`, `CD-BCN` |
| name | string | |
| address | text, optional | |
| active | boolean | Inactivo: no nuevas operaciones |
| timestamps | | |

#### `categories`
| Campo | Tipo | Notas |
|-------|------|-------|
| id | PK | |
| name | string, unique | |
| parent_id | FK optional | Jerarquía simple (1 nivel en MVP) |
| active | boolean | |
| timestamps | | |

#### `products`
| Campo | Tipo | Notas |
|-------|------|-------|
| id | PK | |
| sku | string, unique | |
| name | string | |
| category_id | FK | |
| unit_type | enum | `unidad`, `caja`, `paquete`, `kg`, `litro` |
| barcode | string, nullable, unique | Opcional v1 |
| min_stock_level | decimal, optional | Alerta P1; campo presente, lógica P1 |
| active | boolean | |
| timestamps | | |

> **Extensibilidad unidades (v2):** tabla `unit_conversions` (`product_id`, `from_unit`, `to_unit`, `factor`) sin usar en v1.

#### `locations`
| Campo | Tipo | Notas |
|-------|------|-------|
| id | PK | |
| warehouse_id | FK | |
| code | string | Único por almacén. Ej. `A-01-03` |
| aisle | string | |
| rack | string | |
| position | string | |
| active | boolean | |
| timestamps | | |

**Índice único:** `(warehouse_id, code)`

#### `stock_levels`
| Campo | Tipo | Notas |
|-------|------|-------|
| id | PK | |
| product_id | FK | |
| location_id | FK | |
| warehouse_id | FK | Denormalizado para consultas |
| quantity_on_hand | decimal(15,3) | Físico en ubicación |
| quantity_reserved | decimal(15,3) | Reservado por salidas en curso |
| timestamps | | |

**Índice único:** `(product_id, location_id)`  
**Disponible:** `quantity_on_hand - quantity_reserved` (calculado, no persistido)

#### `stock_movements` (auditoría inmutable)
| Campo | Tipo | Notas |
|-------|------|-------|
| id | PK | |
| product_id | FK | |
| warehouse_id | FK | |
| location_id | FK, nullable | Null en transferencias agregadas |
| movement_type | enum | `reception`, `outbound`, `transfer_out`, `transfer_in`, `adjustment`, `cancellation` |
| quantity | decimal | Positivo entrada, negativo salida |
| quantity_before | decimal | |
| quantity_after | decimal | |
| reference_type | string | Polimórfico: `ReceptionLine`, `PickingLine`, etc. |
| reference_id | bigint | |
| user_id | FK | |
| notes | text, optional | |
| occurred_at | datetime | |
| cancelled_at | datetime, nullable | Si fue revertido |
| timestamps | | |

#### `reception_orders` / `reception_lines`
- **Order:** `warehouse_id`, `supplier_name`, `reference_number`, `status` (`draft`, `partial`, `completed`, `cancelled`), `received_by`, timestamps
- **Line:** `reception_order_id`, `product_id`, `expected_quantity`, `received_quantity`, `location_id` (al confirmar), `status`

#### `outbound_orders` / `outbound_lines` / `picking_lines`
- **Order:** `warehouse_id`, `customer_name`, `reference_number`, `status` (`draft`, `picking`, `partial`, `completed`, `cancelled`)
- **Line:** `product_id`, `requested_quantity`, `picked_quantity`, `status`
- **PickingLine:** `outbound_line_id`, `location_id`, `quantity_to_pick`, `quantity_picked`, `sequence` (orden por ubicación)

#### `transfer_orders` / `transfer_lines`
- **Order:** `origin_warehouse_id`, `destination_warehouse_id`, `status` (`draft`, `in_transit`, `partial`, `completed`, `cancelled`), `shipped_at`, `received_at`
- **Line:** `product_id`, `requested_quantity`, `shipped_quantity`, `received_quantity`

**Regla:** Al enviar (`in_transit`), se descuenta stock en origen. Al recibir en destino, se incrementa en ubicación de recepción del almacén destino.

#### `inventory_counts` / `inventory_count_lines`
- **Count:** `warehouse_id`, `status` (`in_progress`, `submitted`, `closed`), `started_by`, `submitted_at`
- **Line:** `product_id`, `location_id`, `system_quantity`, `counted_quantity`, `variance`

#### `inventory_adjustments` / `inventory_adjustment_lines`
- **Adjustment:** `source_type` (`manual`, `count`), `inventory_count_id` nullable, `status` (`pending`, `approved`, `rejected`), `requested_by`, `approved_by`, `reason`, timestamps
- **Line:** `product_id`, `location_id`, `quantity_before`, `quantity_change`, `quantity_after`

#### `movement_cancellations`
| Campo | Tipo | Notas |
|-------|------|-------|
| stock_movement_id | FK | Movimiento a revertir |
| status | enum | `pending`, `approved`, `rejected` |
| requested_by | FK | |
| approved_by | FK, nullable | |
| reason | text | Obligatorio |
| reversal_movement_id | FK, nullable | Movimiento compensatorio al aprobar |

#### `external_references` (preparación ERP)
| Campo | Tipo | Notas |
|-------|------|-------|
| referable_type | string | `Product`, `Warehouse`, etc. |
| referable_id | bigint | |
| source_system | string | Ej. `erp` |
| external_id | string | ID en sistema externo |
| last_synced_at | datetime, nullable | |

**Índice único:** `(source_system, external_id, referable_type)`

#### `users` / roles
- Rol almacenado como enum en `users.role`: `admin`, `supervisor`, `operario`, `consulta`
- Autenticación: según stack del proyecto (Devise u equivalente)

### Servicios de dominio (preliminares)

| Servicio | Responsabilidad |
|----------|-----------------|
| `StockUpdater` | Único punto de mutación de `stock_levels`; siempre crea `stock_movement` |
| `ReservationService` | Reserva/libera stock al crear picking |
| `AdjustmentWorkflow` | Solicitud → aprobación → aplicación vía `StockUpdater` |
| `CancellationWorkflow` | Solicitud → aprobación → movimiento compensatorio |
| `Integration::ProductImporter` | Interfaz: `#import(row)` → `Product`; implementación stub en v1 |
| `Integration::ImportResult` | Value object: `success`, `errors`, `record` |

---

## Reglas de negocio transversales

1. **SKU único** a nivel sistema; **código de ubicación único** por almacén.
2. **Barcode único** cuando está presente (puede ser null).
3. **Stock nunca negativo** en `quantity_on_hand` ni en disponible (`on_hand - reserved`).
4. **Mutación de stock** solo a través de `StockUpdater` (servicio transaccional).
5. **Movimientos auditados** son append-only; correcciones vía movimiento compensatorio o cancelación aprobada.
6. **Salidas normales** no requieren aprobación de supervisor.
7. **Ajustes, correcciones de conteo y cancelaciones** requieren aprobación de `supervisor` o `admin`.
8. **Almacén inactivo:** no permite nuevas recepciones, salidas ni transferencias; consulta permitida.
9. **Producto inactivo:** no aparece en nuevas órdenes; stock existente sigue visible.
10. **Transferencia:** stock sale del origen al marcar `in_transit`; entra al destino al confirmar recepción de transferencia.
11. **Sin conversiones de unidad:** cantidades siempre en la unidad del producto.

---

## Criterio de MVP listo

La empresa puede operar durante **2 semanas** con al menos **2 almacenes** activos:

- Recepciones y salidas diarias sin Excel
- Al menos 1 transferencia entre almacenes completada
- 1 ciclo de conteo con ajuste aprobado
- 1 cancelación de movimiento aprobada
- Consulta de stock consolidada y por almacén
- Auditoría consultable por producto

---

## Roadmap de implementación por ramas

Diseñado para **2–3 desarrolladores** trabajando en paralelo con merges frecuentes a `main` (o `develop`). Cada rama es un vertical slice mergeable con feature flags si aplica.

### Convenciones

- Prefijo de rama: `feature/warehouse-<slice>`
- Cada rama incluye: migraciones, modelos, servicios, API/UI mínima, tests del slice
- **No iniciar slice N+1** hasta que las migraciones del slice N estén en la rama base

### Fase 0 — Fundación (Semana 1)

| Rama | Owner sugerido | Entregables | Historias |
|------|----------------|-------------|-----------|
| `feature/warehouse-auth-rbac` | Dev C | Users, roles, políticas Pundit/CanCan, layout base | US-040 |
| `feature/warehouse-master-data` | Dev A | Warehouses, categories, products, locations, `ExternalReference` stub | US-001, US-002, US-003, US-004 |
| `feature/warehouse-stock-core` | Dev B | `stock_levels`, `stock_movements`, `StockUpdater`, carga inicial CSV | US-005, US-041 (parcial) |

**Merge order:** auth → master-data → stock-core

```mermaid
gantt
    title Roadmap MVP WMS (6-8 semanas)
    dateFormat YYYY-MM-DD
    section Fase0
    auth-rbac           :a1, 2026-06-17, 5d
    master-data         :a2, 2026-06-17, 7d
    stock-core          :a3, after a2, 5d
    section Fase1
    reception           :b1, after a3, 7d
    inventory-query     :b2, after a3, 4d
    section Fase2
    outbound-picking    :c1, after b1, 10d
    section Fase3
    count-adjustments   :d1, after c1, 7d
    transfers           :d2, after b1, 7d
    cancellations       :d3, after d1, 5d
```

### Fase 1 — Entradas y consulta (Semana 2–3)

| Rama | Owner | Entregables | Historias |
|------|-------|-------------|-----------|
| `feature/warehouse-reception` | Dev B | Reception orders, confirmación, integración `StockUpdater` | US-010, US-011 |
| `feature/warehouse-inventory-query` | Dev A | Búsqueda por SKU/nombre/categoría, filtros multi-almacén | US-030 |

**Paralelo:** Dev B recepción + Dev A consulta (ambos dependen de stock-core).

### Fase 2 — Salidas (Semana 3–5)

| Rama | Owner | Entregables | Historias |
|------|-------|-------------|-----------|
| `feature/warehouse-outbound` | Dev C | Outbound orders, reservas, alertas stock | US-020, US-023 |
| `feature/warehouse-picking` | Dev C | Picking list, confirmación, decremento stock | US-021, US-022 |

**Secuencial dentro del equipo C:** outbound → picking (misma rama o sub-ramas).

### Fase 3 — Control y transferencias (Semana 5–7)

| Rama | Owner | Entregables | Historias |
|------|-------|-------------|-----------|
| `feature/warehouse-transfers` | Dev A | Transfer orders, in_transit, recepción destino | US-034 |
| `feature/warehouse-counts` | Dev B | Conteo, solicitud corrección | US-031, US-032 |
| `feature/warehouse-adjustments-approval` | Dev B | Flujo aprobación ajustes | US-033 |
| `feature/warehouse-cancellations` | Dev C | Cancelación movimientos confirmados | US-035 |

**Paralelo:** transfers (A) + counts/adjustments (B) + cancellations (C) tras picking mergeado.

### Fase 4 — Integración stub y hardening (Semana 7–8)

| Rama | Owner | Entregables |
|------|-------|-------------|
| `feature/warehouse-integration-stub` | Dev A | `Integration::ProductImporter`, README integración, tests contrato |
| `feature/warehouse-audit-ui` | Dev C | US-041 UI completa, export CSV movimientos |
| `fix/warehouse-e2e-hardening` | Todos | Pruebas E2E flujos críticos, corrección bugs |

### Asignación sugerida por desarrollador

| Dev | Foco principal | Ramas |
|-----|----------------|-------|
| **Dev A** | Datos maestros, consultas, transferencias, integración | master-data, inventory-query, transfers, integration-stub |
| **Dev B** | Stock core, recepción, conteos y aprobaciones | stock-core, reception, counts, adjustments-approval |
| **Dev C** | Auth, salidas, picking, cancelaciones, auditoría UI | auth-rbac, outbound, picking, cancellations, audit-ui |

### Puntos de sincronización (daily / twice-weekly)

1. **Contrato `StockUpdater`** — bloqueante para reception, picking, transfers, adjustments
2. **Estados de órdenes** — enum compartido documentado antes de outbound
3. **Políticas de autorización** — matriz rol × acción antes de aprobaciones

---

## Preparación integración ERP (v2)

```
app/
  services/
    integration/
      base_importer.rb       # interface común
      product_importer.rb    # stub v1; implementación ERP v2
      import_result.rb
  models/
    external_reference.rb
```

**Contrato `ProductImporter#import(row)`:**
- Input: `{ sku:, name:, category_name:, unit_type:, barcode: nil, external_id: }`
- Output: `ImportResult` con producto creado/actualizado o errores de validación
- Idempotente por `external_id` + `source_system: 'erp'`

---

## Technical Considerations

- Stack objetivo: Rails + MySQL + React/Inertia (según estándares del proyecto)
- Transacciones DB en todos los flujos de stock
- **ADR-0001:** `Warehouse::StockUpdater` como único writer de inventario — [Accepted](../architecture/adr-0001-stock-updater-single-writer.md)
- **ADR-0002:** Reservas location-level al iniciar picking — [Accepted](../architecture/adr-0002-outbound-stock-reservations.md)
- **ADR-0003:** Asignación greedy por orden de ubicación — [Accepted](../architecture/adr-0003-picking-location-allocation.md)
- **ADR-0004:** Namespace `Warehouse::` y estructura de módulo — [Accepted](../architecture/adr-0004-warehouse-module-boundaries.md)
- **ADR-0005:** Capa `Integration::*` para ERP futuro — [Accepted](../architecture/adr-0005-erp-integration-layer.md)
- Diseño técnico: [warehouse-mvp.md](../design/warehouse-mvp.md)
- Revisión arquitectura: [warehouse-mvp-review.md](../architecture/warehouse-mvp-review.md) — **APPROVED WITH CONDITIONS**
- Performance: índices en `stock_levels(warehouse_id, product_id)`, `stock_movements(product_id, occurred_at)`
- Seguridad: RBAC en API y UI; auditoría no editable

## Dependencies

- Ninguna integración externa en v1
- Infraestructura según `.ai/standards/aws-infrastructure.md` cuando exista app desplegada

## Open Questions

- [ ] ¿Proveedor se modela como entidad o campo texto en recepción? → **MVP: campo texto `supplier_name`**
- [ ] ¿Cliente en salida: entidad o texto? → **MVP: campo texto `customer_name`**
- [ ] ¿Límite de almacenes en v1? → **Sin límite técnico; operación esperada: 2–10**

## Approval

- [x] Product Owner sign-off
- [x] Rails Architect review — APPROVED WITH CONDITIONS (2026-06-16)
- [x] MySQL DBA review — APPROVED WITH CONDITIONS (2026-06-16) — [migrations review](../architecture/warehouse-mvp-migrations-review.md)
