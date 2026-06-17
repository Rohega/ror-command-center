# frozen_string_literal: true

class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products, charset: "utf8mb4", collation: "utf8mb4_unicode_ci" do |t|
      t.string :sku, null: false
      t.string :name, null: false
      t.references :category, null: false, foreign_key: true, index: true
      t.string :unit_type, null: false, limit: 20
      t.string :barcode, limit: 64
      t.decimal :min_stock_level, precision: 15, scale: 3
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :products, :sku, unique: true
    add_index :products, :barcode, unique: true
    add_index :products, :name
    add_index :products, :active
  end
end

# unit_type values: unidad, caja, paquete, kg, litro
