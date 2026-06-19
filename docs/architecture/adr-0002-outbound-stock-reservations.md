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
