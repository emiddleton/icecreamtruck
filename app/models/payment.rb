# frozen_string_literal: false

class Payment
  include ActiveModel::Serializers::JSON
  attr_accessor :card_number, :expiry_date

  def attributes
    { 'card_number' => nil, 'expiry_date' => nil }
  end
end
