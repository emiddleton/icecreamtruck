# frozen_string_literal: false

class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :item

  delegate :name, to: :item

  def stock?
    item.quantity.positive?
  end

  def cost
    quantity * item.price
  end

  def reserve_items!
    item.decrement!(:quantity, quantity)
  end

  def return_items!
    item.increment!(:quantity, quantity)
  end

  def account_for_sales!
    item.increment!(:sales, quantity * item.price)
  end

  def revert_sales!
    item.decrement!(:sales, quantity * item.price)
  end

  def attributes
    { 'item_id' => nil, 'name' => nil, 'quantity' => nil }
  end
end
