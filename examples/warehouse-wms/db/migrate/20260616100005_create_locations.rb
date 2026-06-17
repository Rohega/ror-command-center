# frozen_string_literal: true

class CreateLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :locations, charset: "utf8mb4", collation: "utf8mb4_unicode_ci" do |t|
      t.references :warehouse, null: false, foreign_key: true, index: true
      t.string :code, null: false
      t.string :aisle, null: false
      t.string :rack, null: false
      t.string :position, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :locations, %i[warehouse_id code], unique: true
    add_index :locations, %i[warehouse_id aisle rack position], name: "index_locations_on_warehouse_pick_path"
    add_index :locations, :active
  end
end
