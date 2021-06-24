# frozen_string_literal: false

class PaymentException < StandardError
  def message
    'Failed to connect to payment provider'
  end
end
