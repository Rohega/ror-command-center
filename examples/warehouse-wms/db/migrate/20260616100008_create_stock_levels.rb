# frozen_string_literal: true

class CreateStockLevels < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_levels, charset: "utf8mb4", collation: "utf8mb4_unicode_ci" do |t|
      t.references :product, null: false, foreign_key: true, index: true
      t.references :location, null: false, foreign_key: true, index: true
      t.references :warehouse, null: false, foreign_key: true, index: true
      t.decimal :quantity_on_hand, precision: 15, scale: 3, null: false, default: 0
      t.decimal :quantity_reserved, precision: 15, scale: 3, null: false, default: 0

      t.timestamps
    end

    add_index :stock_levels, %i[product_id location_id], unique: true
    add_index :stock_levels, %i[warehouse_id product_id]
  end
end
