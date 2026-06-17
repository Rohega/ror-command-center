# frozen_string_literal: true

module Warehouse
  class InsufficientStockError < StandardError; end

  class StockUpdater
    class << self
      def increment!(product:, location:, quantity:, movement_type:, reference:, user:, notes: nil)
        raise ArgumentError, "quantity must be positive" unless quantity.positive?

        apply_quantity_change!(
          product: product,
          location: location,
          on_hand_delta: quantity,
          reserved_delta: 0,
          movement_type: movement_type,
          reference: reference,
          user: user,
          notes: notes
        )
      end

      def decrement!(product:, location:, quantity:, movement_type:, reference:, user:, notes: nil)
        raise ArgumentError, "quantity must be positive" unless quantity.positive?

        apply_quantity_change!(
          product: product,
          location: location,
          on_hand_delta: -quantity,
          reserved_delta: 0,
          movement_type: movement_type,
          reference: reference,
          user: user,
          notes: notes
        )
      end

      def reserve!(product:, location:, quantity:, reference:, user:)
        apply_quantity_change!(
          product: product,
          location: location,
          on_hand_delta: 0,
          reserved_delta: quantity,
          movement_type: "reservation",
          reference: reference,
          user: user,
          notes: "reserve"
        )
      end

      def release!(product:, location:, quantity:, reference:, user:)
        apply_quantity_change!(
          product: product,
          location: location,
          on_hand_delta: 0,
          reserved_delta: -quantity,
          movement_type: "reservation",
          reference: reference,
          user: user,
          notes: "release"
        )
      end

      private

      def apply_quantity_change!(product:, location:, on_hand_delta:, reserved_delta:,
                                 movement_type:, reference:, user:, notes:)
        raise ArgumentError, "invalid location warehouse" if location.warehouse_id.nil?

        StockLevel.transaction do
          level = find_or_create_locked_level!(product, location)
          assert_warehouse_coherence!(level, location)

          before_on_hand = level.quantity_on_hand
          before_reserved = level.quantity_reserved

          new_on_hand = before_on_hand + on_hand_delta
          new_reserved = before_reserved + reserved_delta

          if new_on_hand.negative? || new_reserved.negative?
            raise InsufficientStockError, "negative stock not allowed"
          end
          if (new_on_hand - new_reserved).negative?
            raise InsufficientStockError, "available stock would be negative"
          end

          level.update!(
            quantity_on_hand: new_on_hand,
            quantity_reserved: new_reserved
          )

          next if on_hand_delta.zero? && reserved_delta.zero?

          StockMovement.create!(
            product: product,
            warehouse_id: location.warehouse_id,
            location: location,
            movement_type: movement_type,
            quantity: on_hand_delta.nonzero? ? on_hand_delta : reserved_delta,
            quantity_before: before_on_hand,
            quantity_after: new_on_hand,
            reference: reference,
            user: user,
            notes: notes,
            occurred_at: Time.current
          )

          level
        end
      end

      def find_or_create_locked_level!(product, location)
        StockLevel.lock.find_or_create_by!(product: product, location: location) do |sl|
          sl.warehouse_id = location.warehouse_id
          sl.quantity_on_hand = 0
          sl.quantity_reserved = 0
        end
      end

      def assert_warehouse_coherence!(level, location)
        return if level.warehouse_id == location.warehouse_id

        raise ArgumentError, "stock_level.warehouse_id mismatch with location"
      end
    end
  end
end
