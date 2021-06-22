# frozen_string_literal: false

require 'rails_helper'
require 'request_helper'

RSpec.describe 'Orders', type: :request do
  include_context 'json'
  include_context 'items'

  def sent_json(order)
    order.to_json(root: true, only: %i[name], method: :payment,
                  include: { order_items: { only: %i[item_id quantity] }, payment: {} })
  end

  def expected_json(order)
    order.to_json(include: { order_items: { only: %i[item_id quantity] } })
  end

  describe 'POST /orders' do
    context 'with a valid order' do
      it 'returns the order' do
        order = build(:order)
        post_json '/orders', sent_json(order)
        expect(response.body).to be_json_eql(expected_json(order)).excluding(
          'status', 'transaction_id'
        )
      end
    end

    context 'when their is insufficient items' do
      it 'returns an error saying SORRY' do
        order = build(:order)
        empty_item = create(:item, quantity: 0)
        order.order_items.build(attributes_for(:order_item).merge(item_id: empty_item.id))
        post_json '/orders', sent_json(order), :unprocessable_entity
        expect(response.body).to be_json_eql(%(
          {
            "message": "Validation failed: SORRY we don't have enough \\"#{empty_item.name}\\" to fulfil your order\"
          }
        ))
      end
    end

    context 'with a missing name' do
      it 'returns an error' do
        order = build(:order)
        order.name = nil
        post_json '/orders', sent_json(order), :unprocessable_entity
        expect(response.body).to be_json_eql(%(
          {
            "message": "Validation failed: Name can't be blank"
          }
        ))
      end
    end

    context 'with no items selected' do
      it 'returns an error' do
        order = build(:order)
        order.order_items = []
        post_json '/orders', sent_json(order), :unprocessable_entity
        expect(response.body).to be_json_eql(%(
          {
            "message": "Validation failed: Order items can't be blank"
          }
        ))
      end
    end

    context 'without payment information' do
      it 'returns an error' do
        order = build(:order)
        order.payment = nil
        post_json '/orders', sent_json(order), :unprocessable_entity
        expect(response.body).to be_json_eql(%(
          {
            "message": "Validation failed: Payment information must be provided"
          }
        ))
      end
    end
  end

  describe 'PUT /orders/:id/cancel' do
    context 'when order.status is :payed' do
      it 'will succeed' do
        order = build(:order)
        order.handle_payment!
        put_json "/orders/#{order.id}/cancel"
      end
      it 'will succeed' do
        order = build(:order)
        order.handle_payment!
        order.complete_sale!
        put_json "/orders/#{order.id}/cancel"
      end
    end
    context 'when order.status is :completed' do
      context 'when changed to :canceled' do
        it 'will succeed'
      end
    end
  end

  describe 'GET /orders' do
    context 'when there are orders' do
      it 'returns all registered items'
    end
    context 'when there are many orders' do
      it 'returns the first 20 registered items'
    end
  end
end
