# ADR-0003: Asignación de ubicaciones en picking (greedy ordenado)

## Status

Accepted

## Date

2026-06-16

## Context

US-021 requiere generar `picking_lines` con ubicaciones y cantidades, ordenadas para recorrido eficiente. La spec menciona "FIFO por ubicación" pero no define comportamiento con stock en múltiples posiciones ni productos sin lotes. El MVP excluye FEFO/FIFO por caducidad (non-goal).

## Decision

Implementar estrategia **`Warehouse::Picking::LocationAllocator`** con algoritmo **greedy por orden de ubicación**:

1. Obtener `stock_levels` del producto en el almacén con `disponible > 0`.
2. Ordenar por `locations.aisle`, `locations.rack`, `locations.position` (ASC, lexicográfico).
3. Consumir disponible de la primera ubicación hasta cubrir cantidad solicitada; si insuficiente, continuar con la siguiente.
4. Emitir una `picking_line` por cada ubicación utilizada.

### Parámetros MVP

- Sin optimización de ruta (non-goal confirmado).
- Sin lotes ni caducidad.
- Si el total disponible < solicitado: **no generar picking**; `StartPicking` falla con déficit (US-023).

### Secuencia de picking

Campo `sequence` en `picking_lines` asignado tras ordenar líneas generadas por la misma regla aisle → rack → position.

## Alternatives Considered

| Option | Pros | Cons |
|--------|------|------|
| **A: Greedy por orden de ubicación (elegida)** | Predecible, fácil de explicar al operario, suficiente para MVP | No minimiza distancia real; no es FIFO real por fecha de entrada |
| **B: FIFO por fecha de último movimiento de entrada** | Mejor rotación de stock | Requiere join con `stock_movements`; más complejo; lotes ausentes en MVP |
| **C: Operario elige ubicación manualmente** | Flexible | Más errores; más lento; contradice US-021 auto-generación |

## Consequences

### Positive

- Algoritmo determinista y testeable con fixtures de ubicaciones.
- Evolución v2: sustituir allocator sin cambiar contrato de `Picking::GenerateLines`.

### Negative

- No garantiza rotación óptima de inventario; aceptable según non-goals.
- Productos en muchas ubicaciones generan muchas `picking_lines` (paginación UI recomendada).

## Compliance

- Standards: `.ai/standards/development.md`
- Stories blocked until Accepted: US-021, US-022
- Depends on: ADR-0002
