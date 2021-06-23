# frozen_string_literal: false

class Item < ApplicationRecord
  has_many :order_items, dependent: :restrict_with_exception

  default_scope { order(created_at: :asc) }
end
