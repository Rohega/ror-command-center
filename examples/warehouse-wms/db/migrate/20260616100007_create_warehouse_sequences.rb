# frozen_string_literal: true

class CreateWarehouseSequences < ActiveRecord::Migration[8.0]
  def change
    create_table :warehouse_sequences, charset: "utf8mb4", collation: "utf8mb4_unicode_ci" do |t|
      t.string :prefix, null: false, limit: 8
      t.integer :year, null: false
      t.integer :last_value, null: false, default: 0

      t.timestamps
    end

    add_index :warehouse_sequences, %i[prefix year], unique: true
  end
end
