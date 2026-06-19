> Language: English | [Español](#versión-en-español)

# ADR-0001: StockUpdater as the single writer of inventory

## Status

Accepted

## Date

2026-06-16

## Context

The WMS MVP needs full traceability (G2), stock that can never go negative (cross-cutting rule #3), and several flows that change inventory: receiving, picking, transfers, approved adjustments, and cancellations. Without a single place to write inventory, the risk of inconsistencies, double deductions, and incomplete audit trails is high — especially with 2–3 developers working at the same time.

## Decision

Every change to `stock_levels` (the `quantity_on_hand` and `quantity_reserved` fields) **must** go through the `Warehouse::StockUpdater` service. No model, callback, or controller changes those fields directly.

### Public contract

```ruby
# app/services/warehouse/stock_updater.rb
module Warehouse
  class StockUpdater
    # Incrementa on_hand (recepción, transfer_in, ajuste positivo, cancelación de salida)
    def self.increment!(product:, location:, quantity:, movement_type:, reference:, user:, notes: nil)
    end

    # Decrementa on_hand (picking confirmado, transfer_out, ajuste negativo)
    def self.decrement!(product:, location:, quantity:, movement_type:, reference:, user:, notes: nil)
    end

    # Reserva / libera reserved sin cambiar on_hand
    def self.reserve!(product:, location:, quantity:, reference:, user:)
    end

    def self.release!(product:, location:, quantity:, reference:, user:)
    end
  end
end
```

### Implementation rules

1. Each call runs inside an **ActiveRecord transaction** with `stock_levels.lock!` (a pessimistic lock on the `product_id + location_id` row).
2. After changing `stock_levels`, it creates an append-only `stock_movements` record with `quantity_before`, `quantity_after`, a polymorphic `reference`, and `user_id`.
3. It validates `quantity_on_hand >= 0` and `quantity_on_hand - quantity_reserved >= 0` after each operation; it raises `Warehouse::InsufficientStockError` if the check fails.
4. The `warehouse_id` in `stock_levels` is always derived from `location.warehouse_id` when writing; a consistency check is mandatory.
5. Integration tests cover concurrency (2 threads trying to decrement the same stock).

## Alternatives Considered

| Option | Pros | Cons |
|--------|------|------|
| **A: Centralized StockUpdater (chosen)** | Guaranteed audit trail; one place for locks and validations | Theoretical bottleneck; requires team discipline |
| **B: Callbacks on order models** | Less explicit code in services | Logic scattered around; hard to test; callbacks hide the flow |
| **C: Full event sourcing** | Traceability built in | Over-engineering for an MVP; steep learning curve |

## Consequences

### Positive

- A stable contract for the 3 developers; receiving, picking, and transfers are decoupled from the persistence details.
- A 1:1 audit trail between stock changes and `stock_movements`.
- Makes cancellations easier through a compensating movement (ADR implied in US-035).

### Negative

- `StockUpdater` becomes a blocking dependency from Phase 1 onward; it must be merged before receiving/outbound.
- Every new stock operation requires extending the service (discipline, not a direct workaround).

## Compliance

- Standards: `.ai/standards/development.md` (service objects for multi-step workflows)
- Stories blocked until Accepted: US-005, US-011, US-022, US-033, US-034, US-035

---

## Versión en español

# ADR-0001: StockUpdater como único escritor de inventario

## Status

Accepted

## Date

2026-06-16

## Context

El WMS MVP requiere trazabilidad completa (G2), stock nunca negativo (regla transversal #3) y múltiples flujos que mutan inventario: recepción, picking, transferencias, ajustes aprobados y cancelaciones. Sin un punto único de escritura, el riesgo de inconsistencias, doble descuento y auditoría incompleta es alto — especialmente con 2–3 desarrolladores en paralelo.

## Decision

Toda mutación de `stock_levels` (campos `quantity_on_hand` y `quantity_reserved`) **debe** pasar por el servicio `Warehouse::StockUpdater`. Ningún modelo, callback ni controlador modifica esos campos directamente.

### Contrato público

```ruby
# app/services/warehouse/stock_updater.rb
module Warehouse
  class StockUpdater
    # Incrementa on_hand (recepción, transfer_in, ajuste positivo, cancelación de salida)
    def self.increment!(product:, location:, quantity:, movement_type:, reference:, user:, notes: nil)
    end

    # Decrementa on_hand (picking confirmado, transfer_out, ajuste negativo)
    def self.decrement!(product:, location:, quantity:, movement_type:, reference:, user:, notes: nil)
    end

    # Reserva / libera reserved sin cambiar on_hand
    def self.reserve!(product:, location:, quantity:, reference:, user:)
    end

    def self.release!(product:, location:, quantity:, reference:, user:)
    end
  end
end
```

### Reglas de implementación

1. Cada llamada ejecuta en **transacción ActiveRecord** con `stock_levels.lock!` (bloqueo pesimista en la fila `product_id + location_id`).
2. Tras mutar `stock_levels`, crea un registro `stock_movements` append-only con `quantity_before`, `quantity_after`, `reference` polimórfico y `user_id`.
3. Valida `quantity_on_hand >= 0` y `quantity_on_hand - quantity_reserved >= 0` tras cada operación; lanza `Warehouse::InsufficientStockError` si falla.
4. `warehouse_id` en `stock_levels` se deriva siempre de `location.warehouse_id` en escritura; validación de coherencia obligatoria.
5. Tests de integración cubren concurrencia (2 threads intentando decrementar el mismo stock).

## Alternatives Considered

| Option | Pros | Cons |
|--------|------|------|
| **A: StockUpdater centralizado (elegida)** | Auditoría garantizada; un lugar para locks y validaciones | Cuello de botella teórico; requiere disciplina del equipo |
| **B: Callbacks en modelos de orden** | Menos código explícito en servicios | Dispersión de lógica; difícil de testear; callbacks ocultan flujo |
| **C: Event sourcing completo** | Trazabilidad nativa | Sobre-ingeniería para MVP; curva de aprendizaje alta |

## Consequences

### Positive

- Contrato estable para los 3 desarrolladores; reception, picking y transfers desacoplados del detalle de persistencia.
- Auditoría 1:1 entre cambios de stock y `stock_movements`.
- Facilita cancelaciones mediante movimiento compensatorio (ADR implícito en US-035).

### Negative

- `StockUpdater` se convierte en dependencia bloqueante de Fase 1+; debe mergearse antes de reception/outbound.
- Toda nueva operación de stock requiere extender el servicio (disciplina, no workaround directo).

## Compliance

- Standards: `.ai/standards/development.md` (service objects para workflows multi-paso)
- Stories blocked until Accepted: US-005, US-011, US-022, US-033, US-034, US-035
