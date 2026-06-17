# frozen_string_literal: true

class CreateStockMovements < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_movements, charset: "utf8mb4", collation: "utf8mb4_unicode_ci" do |t|
      t.references :product, null: false, foreign_key: true, index: true
      t.references :warehouse, null: false, foreign_key: true, index: true
      t.references :location, foreign_key: true, index: true
      t.string :movement_type, null: false, limit: 32
      t.decimal :quantity, precision: 15, scale: 3, null: false
      t.decimal :quantity_before, precision: 15, scale: 3, null: false
      t.decimal :quantity_after, precision: 15, scale: 3, null: false
      t.string :reference_type
      t.bigint :reference_id
      t.references :user, null: false, foreign_key: true, index: true
      t.text :notes
      t.datetime :occurred_at, null: false
      t.datetime :cancelled_at

      t.timestamps
    end

    add_index :stock_movements, %i[product_id occurred_at]
    add_index :stock_movements, %i[warehouse_id occurred_at]
    add_index :stock_movements, %i[reference_type reference_id]
    add_index :stock_movements, :movement_type
  end
end

# movement_type: reception, outbound, transfer_out, transfer_in, adjustment, cancellation
