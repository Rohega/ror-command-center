# frozen_string_literal: true

class CreateWarehouses < ActiveRecord::Migration[8.0]
  def change
    create_table :warehouses, charset: "utf8mb4", collation: "utf8mb4_unicode_ci" do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.text :address
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :warehouses, :code, unique: true
    add_index :warehouses, :active
  end
end
