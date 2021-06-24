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
    update_from_to_status!(:payed, :completed, already: 'Already completed.', from: 'Payment must be completed.') do
      order_items.each(&:account_for_sales!)
    end
  end

  def cancel!
    retries ||= 0
    revert_sale! if completed?
    revert_payment! if payed?
    return_stock!(:paying, :check_refund) if paying?
    return_stock!(:reserved, :canceled) if reserved?
  rescue StandardError => e
    retry if (retries += 1) < 5
    raise e
  end

  private

  def reserve_stock!
    update_from_to_status!(:canceled, :reserved, retries: 0) do
      order_items.each do |order_item|
        unless order_item.stock?
          errors.add(:base, "SORRY we don't have enough #{order_item.name.inspect} to fulfil your order")
          raise ActiveRecord::RecordInvalid, self
        end
      end
      order_items.each(&:reserve_items!)
    end
  end

  # try to return stock in a transaction so that either all stock is returned or none.
  def return_stock!(from_status, new_status)
    update_from_to_status!(from_status, new_status, noop: true) do
      order_items.each(&:return_items!)
    end
  end

  def total_cost
    order_items.sum(&:cost)
  end

  def request_payment!
    update_from_to_status!(:reserved, :paying)
    payment_provider!("connecting to payment provider to make payment of #{total_cost}")
    update_from_to_status!(:paying, :payed)
  end

  def revert_payment!
    update_from_to_status!(:payed, :refunding)
    payment_provider!("connecting to payment provider to revert payment of #{total_cost}")
    update_from_to_status!(:refunding, :refund)
  end

  def payment_provider!(message)
    logger.info(message)
    sleep(2)
  end

  def revert_sale!
    update_from_to_status!(:completed, :payed, noop: true) do
      order_items.each(&:revert_sales!)
    end
  end

  #
  # *update_from_to_status* wraps a state change in a transaction.
  # *from* is the state it should be in before the action
  # *to* is the state it should be in after the action
  # *opts*
  #   *from:* message for exception if not in *from* state
  #   *already:* message for exception if already in *to* state
  #   *noop*: whether to throw exception if already in *to* state (default: false)
  #   *retries*: number of times to retry if transaction fails
  #
  def update_from_to_status!(from, to, opts = {})
    opts = { from: "Must have #{from} status", already: "Already #{to}.", noop: false, retries: 3 }.merge(opts)
    retries ||= 0
    transaction do
      check_status(from, to, opts)
      yield if block_given?
      update!(status: to)
    end
  rescue ActiveRecord::RecordInvalid => e
    raise e
  rescue StandardError => e
    retry if (retries += 1) < opts[:retries]
    raise e
  end

  def check_status(from, to, opts)
    logger.info "checking #{status}, #{from} -> #{to}"
    reload
    if to == status.to_sym && !opts[:noop]
      errors.add(:base, opts[:already])
      raise ActiveRecord::RecordInvalid, self
    elsif from != status.to_sym
      errors.add(:base, opts[:from])
      raise ActiveRecord::RecordInvalid, self
    end
  end
end
