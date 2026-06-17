# Architecture Review: WMS MVP — warehouse-mvp

**Reviewer:** Rails Architect  
**Date:** 2026-06-16  
**Spec:** [warehouse-mvp.md](../specs/warehouse-mvp.md)  
**Verdict:** **APPROVED WITH CONDITIONS**

---

## Summary

La especificación de producto es implementable en Rails monolito con el stack acordado. El modelo de datos es coherente para una distribuidora multi-almacén. Se emiten **5 ADRs Accepted** que gobiernan las decisiones bloqueantes identificadas en la spec.

La implementación puede iniciar en **Fase 0** (`auth-rbac`, `master-data`, `stock-core`) cumpliendo las condiciones listadas al final.

---

## Decisiones arquitectónicas emitidas

| ADR | Título | Estado |
|-----|--------|--------|
| [ADR-0001](adr-0001-stock-updater-single-writer.md) | StockUpdater como único escritor | Accepted |
| [ADR-0002](adr-0002-outbound-stock-reservations.md) | Reservas location-level al iniciar picking | Accepted |
| [ADR-0003](adr-0003-picking-location-allocation.md) | Greedy por orden de ubicación | Accepted |
| [ADR-0004](adr-0004-warehouse-module-boundaries.md) | Namespace `Warehouse::` y estructura | Accepted |
| [ADR-0005](adr-0005-erp-integration-layer.md) | Capa Integration sin acoplamiento Odoo | Accepted |

**Diseño técnico:** [warehouse-mvp.md](../design/warehouse-mvp.md)

---

## Fortalezas del diseño de producto

1. **Vertical slices** del roadmap alineados con dependencias reales de datos.
2. **Auditoría append-only** bien planteada; encaja con cancelaciones compensatorias.
3. **Aprobaciones acotadas** solo donde hay riesgo (ajustes, cancelaciones) — reduce fricción operativa.
4. **Multi-almacén** con transferencias en dos fases es el mínimo viable correcto para distribuidora.
5. **Preparación Odoo** sin sobre-ingeniería (importer + external_references).

---

## Hallazgos y resoluciones

### BLOCKING (resueltos en ADRs)

| # | Hallazgo | Resolución |
|---|----------|------------|
| B1 | Sin contrato único de mutación de stock | ADR-0001 `Warehouse::StockUpdater` |
| B2 | Momento y granularidad de reservas no definidos | ADR-0002 reserva al `start_picking`, por ubicación |
| B3 | Algoritmo de picking ambiguo ("FIFO") | ADR-0003 greedy por aisle/rack/position |
| B4 | Estructura de código para 3 devs en paralelo | ADR-0004 namespace `Warehouse::` |
| B5 | Integración Odoo sin patrón | ADR-0005 `Integration::*` + `ExternalReference` |

### CONCERNS (condiciones de implementación)

| # | Riesgo | Mitigación requerida |
|---|--------|----------------------|
| C1 | `warehouse_id` denormalizado en `stock_levels` puede desincronizarse | Validación en `StockUpdater`; test de coherencia |
| C2 | Transferencia sin ubicación virtual: stock "desaparece" en tránsito | Documentado; UI debe mostrar `in_transit` en reporte de transferencias; no contar como disponible |
| C3 | Cancelación de `transfer_in` ya recibido | US-035 bloquea cancelación simple; forzar transferencia inversa — **añadir test E2E** |
| C4 | Concurrencia en picking | Locks pesimistas ADR-0001 + tests de integración obligatorios |
| C5 | Conteo con stock en movimiento | Snapshot `system_quantity` al **submit** del conteo (confirmado en diseño) |
| C6 | `StartPicking` transacción larga | Mantener allocator O(n) ubicaciones; monitorizar; no requiere job async en MVP |

### SUGGESTIONS (no bloqueantes)

| # | Sugerencia |
|---|------------|
| S1 | Añadir `lock_version` en `reception_lines` y `picking_lines` |
| S2 | Validar cantidades enteras para unidades discretas en modelo `Product` |
| S3 | CSV carga inicial: reutilizar `Integration::ProductImporter` (ADR-0005 dogfooding) |
| S4 | Tabla `warehouse_sequences` para números de documento sin race conditions |
| S5 | ADR futuro de infra: Solid Queue vs Sidekiq cuando exista despliegue AWS |

---

## Ajustes al modelo de datos (vs spec original)

| Entidad | Cambio |
|---------|--------|
| `picking_lines` | + `status` (`pending`, `picked`, `skipped`) |
| `reception_lines` | + `lock_version` |
| `stock_movements` | `location_id` obligatorio en operaciones por ubicación |
| Nueva `warehouse_sequences` | Generación de números `REC/OUT/TRF` |

---

## Orden de merge confirmado

```mermaid
flowchart LR
    A[auth-rbac] --> B[master-data]
    B --> C[stock-core]
    C --> D[reception + inventory-query]
    D --> E[outbound-picking]
    D --> F[transfers]
    E --> G[counts-adjustments]
    E --> H[cancellations]
```

**Gate duro:** ningún PR que escriba `quantity_on_hand` o `quantity_reserved` fuera de `StockUpdater` pasa code review.

---

## Historias desbloqueadas

Todas las P0 quedan **desbloqueadas para implementación** tras este review, con implementación conforme a ADRs 0001–0005 y [diseño técnico](../design/warehouse-mvp.md).

| Fase | Historias | Prerequisito |
|------|-----------|--------------|
| 0 | US-001–004, US-040 | ADR-0004 |
| 0 | US-005, US-041 | ADR-0001, ADR-0004 |
| 1 | US-010–011, US-030 | stock-core mergeado |
| 2 | US-020–023 | ADR-0002, ADR-0003 |
| 3 | US-031–035, US-034 | ADR-0001 |

---

## Conditions (deben cumplirse en PRs)

1. [ ] `Warehouse::StockUpdater` mergeado con tests de concurrencia antes de reception/outbound
2. [ ] Políticas Pundit para matriz US-040 en mismo PR que endpoints mutantes
3. [ ] Migraciones con índices según diseño técnico
4. [ ] Sin gems nuevas sin justificación en ADR
5. [ ] MySQL DBA review en PR con migraciones de `stock_levels` y `stock_movements`

---

## Sign-off

- [x] Rails Architect — **APPROVED WITH CONDITIONS** (2026-06-16)
- [x] ADRs 0001–0005 — **Accepted**
- [x] MySQL DBA review — APPROVED WITH CONDITIONS (2026-06-16) — [migrations review](warehouse-mvp-migrations-review.md)
