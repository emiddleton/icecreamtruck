# frozen_string_literal: false

class CreateItems < ActiveRecord::Migration[6.1]
  def change
    create_table :items, id: :uuid do |t|
      t.text :name, null: false
      t.integer :price, null: false
      t.integer :quantity, null: false
      t.integer :sales, null: false

      t.timestamps
    end
  end
end
