# frozen_string_literal: true

class CreateExternalReferences < ActiveRecord::Migration[8.0]
  def change
    create_table :external_references, charset: "utf8mb4", collation: "utf8mb4_unicode_ci" do |t|
      t.string :referable_type, null: false
      t.bigint :referable_id, null: false
      t.string :source_system, null: false, limit: 32
      t.string :external_id, null: false
      t.datetime :last_synced_at

      t.timestamps
    end

    add_index :external_references, %i[referable_type referable_id]
    add_index :external_references,
              %i[source_system external_id referable_type],
              unique: true,
              name: "index_external_refs_on_source_and_external_id"
  end
end
