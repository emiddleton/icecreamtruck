# frozen_string_literal: false

class Order < ApplicationRecord
  has_many :order_items, inverse_of: :order, dependent: :destroy

  accepts_nested_attributes_for :order_items

  enum status: {
    reserved: 'reserved',        # stock is being reserved to fulfil order
    paying: 'paying',            # order payment is being processed
    refunding: 'refunding',      # order refund is being processed
    payed: 'payed',              # order was payed for but not received
    completed: 'completed',      # order was completed
    canceled: 'canceled',        # order was canceled
    check_refund: 'check_refund' # requires checking with payment provider order canceled but payment status unknown
  }

  validates :name,
            presence: true,
            length: {
              maximum: 255,
              message: 'only supports up to 255 ASCI characters (less for multibyte characters)'
            }
  validates :order_items, presence: true
  validates_each :payment, on: :create do |record, attr, value|
    record.errors.add(attr, 'information must be provided') if value.blank?
  end

  attr_accessor :payment

  def handle_payment!
    self.transaction_id = SecureRandom.uuid
    # if later actions fail it will automatically be canceled
    self.status = :canceled
    save!

    reserve_stock!

    begin
      request_payment!
    rescue StandardError => e
      cancel!
      raise e
    end
  end

  def complete_sale!
    if completed?
      errors.add(:base, 'Already completed.')
      raise ActiveRecord::RecordInvalid, self
    elsif !payed?
      errors.add(:base, 'Payment must be completed.')
      raise ActiveRecord::RecordInvalid, self
    end

    begin
      retries ||= 0
      transaction do
        order_items.each(&:account_for_sales!)
        update!(status: :completed)
      end
    rescue StandardError => e
      retry if (retries += 1) < 3
      raise e
    end
  end

  def cancel!
    retries ||= 0
    revert_sale! if completed?
    revert_payment! if payed?
    return_stock!(:check_refund) if paying?
    return_stock! if reserved?
  rescue StandardError => e
    retry if (retries += 1) < 5
    raise e
  end

  private

  def reserve_stock!
    transaction do
      order_items.each do |order_item|
        unless order_item.stock?
          errors.add(:base, "SORRY we don't have enough #{order_item.name.inspect} to fulfil your order")
          raise ActiveRecord::RecordInvalid, self
        end
      end
      order_items.each(&:reserve_items!)
      reserved!
    end
  end

  # try to return stock in a transaction so that either all stock is returned or none.
  def return_stock!(new_status = :canceled)
    retries ||= 0
    transaction do
      order_items.each(&:return_items!)
      update!(status: new_status)
    end
  rescue StandardError => e
    retry if (retries += 1) < 3
    raise e
  end

  def total_cost
    order_items.sum(&:cost)
  end

  def request_payment!
    paying!
    payment_provider!("connecting to payment provider to make payment of #{total_cost}")
    payed!
  end

  def revert_payment!
    refunding!
    payment_provider!("connecting to payment provider to revert payment of #{total_cost}")
    reserved!
  end

  def payment_provider!(message)
    logger.info(message)
    sleep(2)
  end

  def revert_sale!
    retries ||= 0
    transaction do
      order_items.each(&:revert_sales!)
      update!(status: :payed)
    end
  rescue StandardError => e
    retry if (retries += 1) < 3
    raise e
  end
end
