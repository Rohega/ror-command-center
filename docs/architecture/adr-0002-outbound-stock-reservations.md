> Language: English | [Español](#versión-en-español)

# ADR-0002: Stock reservations for outbound orders (location-level)

## Status

Accepted

## Date

2026-06-16

## Context

Outbound orders move through the states `draft` → `picking` → `completed`. Multiple orders running at the same time on the same warehouse can over-assign stock if we only check availability without reserving. The spec (US-020, US-023) separates draft (no reservation) from picking (with validation). We need to decide **when** to reserve and **at what level of detail**.

## Decision

### When to reserve

| Order state | Reservation |
|--------------|---------|
| `draft` | None |
| `picking`, `partial` | Active reservation per location |
| `completed`, `cancelled` | Reservations released or consumed |

The reservation is created in **`Outbound::StartPicking`** (the `draft` → `picking` transition), not when the draft is created.

### Level of detail

Reserve at the **location level** (`stock_levels.quantity_reserved`), not just an aggregate by product/warehouse.

Flow:

1. `Outbound::AvailabilityChecker` checks aggregate availability per product in the warehouse.
2. `Picking::GenerateLines` assigns locations (ADR-0003).
3. For each `picking_line`, `StockUpdater.reserve!` increases `quantity_reserved` on the matching `stock_level`.
4. When picking is confirmed: `StockUpdater.decrement!` reduces `on_hand` and `release!` releases the reserved portion in the same transaction.
5. When an order is cancelled during picking: `StockUpdater.release!` runs for each pending line.

### Available

```
disponible(location) = quantity_on_hand - quantity_reserved
disponible(almacén, producto) = SUM(disponible(location)) ∀ locations del almacén
```

## Alternatives Considered

| Option | Pros | Cons |
|--------|------|------|
| **A: Reserve per location when picking starts (chosen)** | Avoids assigning the same position twice; aligns with picking lines | More locked rows; line generation required before reserving |
| **B: Aggregate reservation by product/warehouse** | Simpler | Two pickers can reserve the same physical location |
| **C: Reserve when the draft is created** | Locks stock early | Reduces operational availability; abandoned drafts lock stock |

## Consequences

### Positive

- US-023 can be implemented with an aggregate query plus consistency with picking.
- Concurrency controlled with the ADR-0001 locks per `stock_level`.

### Negative

- `StartPicking` is a heavy atomic operation (generate lines + reserve); it must be transactional.
- Regenerating picking with lines already confirmed requires an explicit flow (not automatic in the MVP).

## Compliance

- Standards: `.ai/standards/development.md`, `.ai/standards/mysql.md`
- Stories blocked until Accepted: US-020, US-021, US-022, US-023
- Depends on: ADR-0001, ADR-0003

---

## Versión en español

# ADR-0002: Reservas de stock en salidas (location-level)

## Status

Accepted

## Date

2026-06-16

## Context

Las órdenes de salida pasan por estados `draft` → `picking` → `completed`. Múltiples órdenes concurrentes sobre el mismo almacén pueden sobre-asignar stock si solo se valida disponibilidad sin reservar. La spec (US-020, US-023) distingue borrador (sin reserva) de picking (con validación). Hay que decidir **cuándo** y **a qué granularidad** reservar.

## Decision

### Momento de reserva

| Estado orden | Reserva |
|--------------|---------|
| `draft` | Ninguna |
| `picking`, `partial` | Reserva activa por ubicación |
| `completed`, `cancelled` | Reservas liberadas o consumidas |

La reserva se crea en **`Outbound::StartPicking`** (transición `draft` → `picking`), no al crear el borrador.

### Granularidad

Reserva a **nivel ubicación** (`stock_levels.quantity_reserved`), no solo agregado por producto/almacén.

Flujo:

1. `Outbound::AvailabilityChecker` valida disponibilidad agregada por producto en el almacén.
2. `Picking::GenerateLines` asigna ubicaciones (ADR-0003).
3. Por cada `picking_line`, `StockUpdater.reserve!` incrementa `quantity_reserved` en el `stock_level` correspondiente.
4. Al confirmar picking: `StockUpdater.decrement!` reduce `on_hand` y `release!` la porción reservada en la misma transacción.
5. Al cancelar orden en picking: `StockUpdater.release!` por cada línea pendiente.

### Disponible

```
disponible(location) = quantity_on_hand - quantity_reserved
disponible(almacén, producto) = SUM(disponible(location)) ∀ locations del almacén
```

## Alternatives Considered

| Option | Pros | Cons |
|--------|------|------|
| **A: Reserva por ubicación al iniciar picking (elegida)** | Evita doble asignación de la misma posición; alinea con picking lines | Más filas bloqueadas; generación de líneas obligatoria antes de reservar |
| **B: Reserva agregada por producto/almacén** | Más simple | Dos pickers pueden reservar la misma ubicación física |
| **C: Reserva al crear borrador** | Bloquea stock temprano | Reduce disponibilidad operativa; borradores abandonados bloquean stock |

## Consequences

### Positive

- US-023 implementable con query agregada + coherencia con picking.
- Concurrencia controlada con locks de ADR-0001 por `stock_level`.

### Negative

- `StartPicking` es operación atómica pesada (generar líneas + reservar); debe ser transaccional.
- Regenerar picking con líneas ya confirmadas requiere flujo explícito (no automático en MVP).

## Compliance

- Standards: `.ai/standards/development.md`, `.ai/standards/mysql.md`
- Stories blocked until Accepted: US-020, US-021, US-022, US-023
- Depends on: ADR-0001, ADR-0003
