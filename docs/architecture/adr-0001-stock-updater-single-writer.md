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

- Standards: `.ai/standards/rails-development.md` (service objects para workflows multi-paso)
- Stories blocked until Accepted: US-005, US-011, US-022, US-033, US-034, US-035
