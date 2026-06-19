# ADR-0005: Capa de integración ERP (preparación genérica, sin acoplamiento)

## Status

Accepted

## Date

2026-06-16

## Context

Decisión de producto D1/D6: arranque en blanco en v1, pero arquitectura preparada para importadores de un ERP externo. El anti-pattern a evitar es lógica de dominio condicionada a `if erp?` o modelos con campos específicos del ERP.

## Decision

### Patrón importer

```ruby
# app/services/integration/base_importer.rb
module Integration
  class BaseImporter
    def import(row)
      raise NotImplementedError
    end

    protected

    def find_or_initialize_by_external_reference(referable_class, external_id, source:)
      # ExternalReference.find_by(...) → referable o new
    end
  end
end
```

```ruby
# app/services/integration/product_importer.rb — STUB v1
module Integration
  class ProductImporter < BaseImporter
    SOURCE = "erp".freeze

    def import(row)
      # row: sku, name, category_name, unit_type, barcode, external_id
      # Idempotente por external_id + SOURCE
      ImportResult.new(...)
    end
  end
end
```

### Modelo `ExternalReference`

| Campo | Tipo |
|-------|------|
| `referable` | polimórfico (`Product`, `Warehouse`, …) |
| `source_system` | string (`erp`) |
| `external_id` | string |
| `last_synced_at` | datetime |

Índice único: `(source_system, external_id, referable_type)`.

### Reglas

1. **Dominio no importa** `Integration::*`; solo recibe modelos ya persistidos.
2. v1: `ProductImporter` implementa contrato con persistencia real; fuente CSV manual usando el mismo importer (dogfooding).
3. v2 ERP: nuevo `Integration::Erp::Client` consumido solo por importadores; sin gem del ERP en MVP.
4. Sin cola de outbox en v1; `last_synced_at` suficiente para reconciliación manual.

## Alternatives Considered

| Option | Pros | Cons |
|--------|------|------|
| **A: Importers + ExternalReference (elegida)** | Desacoplamiento; testeable; idempotencia clara | Capa adicional a mantener |
| **B: Campo `erp_id` en products** | Simple al inicio | Deuda técnica; no escala a multi-ERP |
| **C: Sync bidireccional desde v1** | Datos siempre al día | Fuera de scope MVP; complejidad alta |

## Consequences

### Positive

- Carga inicial CSV (US-005) puede reutilizar `ProductImporter` para validar contrato.
- El ERP v2 añade cliente HTTP sin tocar `Warehouse::StockUpdater`.

### Negative

- `ExternalReference` añade joins en importación; negligible en MVP.

## Compliance

- Standards: `.ai/standards/development.md`
- Stories blocked until Accepted: US-002 (stub), US-005 (CSV puede usar importer)
- Depends on: ADR-0004
