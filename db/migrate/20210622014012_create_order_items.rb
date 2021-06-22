# frozen_string_literal: false

class CreateOrderItems < ActiveRecord::Migration[6.1]
  def change
    create_table :order_items, id: :uuid do |t|
      t.references :order, null: false, type: :uuid, foreign_key: true
      t.references :item, null: false, type: :uuid, foreign_key: true
      t.integer :quantity, null: false

      t.timestamps
    end
  end
end
