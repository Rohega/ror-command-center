# Migration Review: WMS MVP — Fase 0 (y esquema completo)

**Reviewer:** MySQL DBA  
**Date:** 2026-06-16  
**Spec:** [warehouse-mvp.md](../specs/warehouse-mvp.md)  
**Design:** [warehouse-mvp.md](../design/warehouse-mvp.md)  
**ADRs:** 0001–0005  
**Reference migrations:** `examples/warehouse-wms/db/migrate/`  
**Verdict:** **APPROVED WITH CONDITIONS**

---

## Scope

Revisión del esquema propuesto para greenfield MySQL 8.x / InnoDB / `utf8mb4_unicode_ci`. Fase 0 cubre tablas maestras + núcleo de inventario. Las tablas operativas (fases 1–3) se incluyen para validar integridad referencial anticipada.

---

## Verdict summary

| Área | Estado |
|------|--------|
| Charset / engine | APPROVED |
| Tipos decimales inventario | APPROVED |
| Índices y FKs Fase 0 | APPROVED |
| Orden de migraciones | APPROVED |
| Tablas operativas (fase 1–3) | APPROVED — implementar en PRs posteriores |
| Concurrencia `stock_levels` | CONDITION — validar en app + tests ADR-0001 |

---

## Fase 0 — Tablas revisadas

### `warehouses`

| Check | Resultado |
|-------|-----------|
| PK bigint | OK |
| `code` UNIQUE | OK — índice único |
| `active` default true | OK |
| Tamaño estimado MVP | < 100 filas — DDL sin riesgo |

### `categories`

| Check | Resultado |
|-------|-----------|
| `parent_id` FK self | OK — índice en FK |
| `name` UNIQUE | OK para MVP; considerar UNIQUE(name, parent_id) en v2 si hay homónimos en ramas distintas |

**CONDITION C-DB-01:** Si se permiten mismos nombres en subcategorías de distintos padres, cambiar a `UNIQUE(name, parent_id)` antes de producción.

### `products`

| Check | Resultado |
|-------|-----------|
| `sku` UNIQUE | OK |
| `barcode` UNIQUE nullable | OK en MySQL 8 (múltiples NULL) |
| `unit_type` tinyint/string | OK como string limit 20 o tinyint enum |
| `category_id` FK + index | OK |
| `decimal` quantities N/A aquí | OK |

### `locations`

| Check | Resultado |
|-------|-----------|
| UNIQUE(warehouse_id, code) | OK |
| FK warehouse_id indexed | OK |

### `external_references`

| Check | Resultado |
|-------|-----------|
| UNIQUE(source_system, external_id, referable_type) | OK |
| Índice (referable_type, referable_id) | OK — requerido para polimórfico |

### `warehouse_sequences`

| Check | Resultado |
|-------|-----------|
| UNIQUE(prefix, year) | OK |
| Uso con SELECT FOR UPDATE | OK — fila por prefijo/año, bajo contention |

### `stock_levels` — tabla crítica

| Check | Resultado |
|-------|-----------|
| UNIQUE(product_id, location_id) | OK |
| INDEX(warehouse_id, product_id) | OK — consulta US-030 |
| `quantity_on_hand` decimal(15,3) | OK |
| `quantity_reserved` decimal(15,3) default 0 | OK |
| `warehouse_id` denormalizado | CONDITION C-DB-02 — CHECK no disponible en todas versiones; **validar en StockUpdater** |

**Recomendación:** trigger opcional v2; MVP confía en capa de aplicación (ADR-0001).

### `stock_movements` — tabla de auditoría

| Check | Resultado |
|-------|-----------|
| Sin UPDATE/DELETE desde app | OK — disciplina aplicación |
| INDEX(product_id, occurred_at) | OK — US-041 |
| INDEX(warehouse_id, occurred_at) | OK |
| INDEX(reference_type, reference_id) | OK |
| Volumen | Crecimiento lineal; particionar por `occurred_at` solo si > 10M filas (post-MVP) |

### `users.role` (extensión Devise)

| Check | Resultado |
|-------|-----------|
| enum string/tinyint | OK — preferir integer enum Rails |
| NOT NULL con default | OK — default `operario` o forzar en seed |

---

## Fases 1–3 — Pre-validación

Las tablas siguientes **no bloquean Fase 0** pero el esquema referencial es coherente:

| Tabla | Notas DBA |
|-------|-----------|
| `reception_orders/lines` | FK warehouse_id, product_id indexados; `lock_version` en lines — OK |
| `outbound_orders/lines` | Índice (warehouse_id, status) para colas operativas |
| `picking_lines` | FK outbound_line_id, location_id; INDEX(location_id) para allocator |
| `transfer_orders/lines` | FK origin + destination warehouse; INDEX(status) |
| `inventory_counts/lines` | UNIQUE opcional (count_id, product_id, location_id) evita duplicados |
| `inventory_adjustments/lines` | OK |
| `movement_cancellations` | UNIQUE(stock_movement_id) donde status pending — evitar doble solicitud |

---

## Findings

### BLOCKED

Ninguno para Fase 0 greenfield.

### CONDITIONS (deben cumplirse en PR)

| ID | Condición |
|----|-----------|
| C-DB-01 | Decidir unicidad de `categories.name` con jerarquía antes de seed producción |
| C-DB-02 | Test de integración: `stock_levels.warehouse_id` == `locations.warehouse_id` |
| C-DB-03 | Todas las FK con índice supporting en migraciones |
| C-DB-04 | `charset: utf8mb4`, `collation: utf8mb4_unicode_ci` explícito en `database.yml` y migraciones |
| C-DB-05 | No usar `float`/`double` para cantidades |

### RECOMMENDATIONS (no bloqueantes)

| ID | Recomendación |
|----|---------------|
| R-DB-01 | `occurred_at` en `stock_movements` default `CURRENT_TIMESTAMP(6)` para precisión |
| R-DB-02 | Semilla staging con EXPLAIN de query US-030 antes de go-live |
| R-DB-03 | Backup + restore test documentado en runbook de despliegue |
| R-DB-04 | `inventory_count_lines`: UNIQUE(inventory_count_id, product_id, location_id) |

---

## Orden de migración confirmado

```
1. Devise users (rails g devise:install)
2. AddRoleToUsers
3. warehouses → categories → products → locations → external_references
4. warehouse_sequences
5. stock_levels → stock_movements
--- merge stock-core gate ---
6. reception_* (Fase 1)
7. outbound_* / picking_lines (Fase 2)
8. transfer_* (Fase 3)
9. inventory_* / movement_cancellations (Fase 3)
```

---

## Sign-off

- [x] MySQL DBA — **APPROVED WITH CONDITIONS** (2026-06-16)
- [ ] Aplicar migraciones en app Rails real y verificar `db:schema:load` + `db:rollback` smoke test
