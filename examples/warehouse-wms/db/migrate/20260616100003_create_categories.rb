# frozen_string_literal: true

class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories, charset: "utf8mb4", collation: "utf8mb4_unicode_ci" do |t|
      t.string :name, null: false
      t.references :parent, foreign_key: { to_table: :categories }, index: true
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :categories, :name, unique: true
    add_index :categories, :active
  end
end
