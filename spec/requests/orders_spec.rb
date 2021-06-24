# frozen_string_literal: false

require 'rails_helper'
require 'request_helper'

RSpec.describe 'Orders', type: :request do
  include_context 'json'
  include_context 'items'

  def sent_json(order)
    order.to_json(root: true, only: %i[name request_id], method: :payment,
                  include: { order_items: { only: %i[item_id quantity] }, payment: {} })
  end

  def expected_json(order)
    order.to_json(include: { order_items: { only: %i[item_id name quantity] } })
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

    context 'with a duplicate order' do
      it 'returns the order' do
        order = build(:order)
        order.handle_payment!

        post_json '/orders', sent_json(order), :conflict
        expect(response.body).to be_json_eql(%(
          {
            "message": "This order has already been received."
          }
        ))
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

  describe 'PUT /orders/:id/complete' do
    context 'when order.status is :payed' do
      it 'will succeed' do
        order = build(:order)
        order.handle_payment!
        put "/orders/#{order.id}/complete", headers: json_headers
        expect(response).to have_http_status(status)
      end
    end

    context 'when order.status is :completed' do
      it 'will fail' do
        order = build(:order)
        order.handle_payment!
        order.complete_sale!
        put_json "/orders/#{order.id}/complete", nil, :unprocessable_entity
        expect(response.body).to be_json_eql(%(
          {
            "message": "Validation failed: Already completed."
          }
        ))
      end
    end

    context 'when order.status is not payed' do
      it 'will fail' do
        order = build(:order)
        order.handle_payment!
        order.update_attribute(:status, :paying)
        put_json "/orders/#{order.id}/complete", nil, :unprocessable_entity
        expect(response.body).to be_json_eql(%(
          {
            "message": "Validation failed: Payment must be completed."
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
    end
    context 'when order.status is :completed' do
      it 'will succeed' do
        order = build(:order)
        order.handle_payment!
        order.complete_sale!
        put_json "/orders/#{order.id}/cancel"
      end
    end
  end

  describe 'GET /orders' do
    it 'returns all registered items' do
      order = build(:order)
      order.handle_payment!
      order.complete_sale!
      get_json '/orders'
      expect(response.body).to have_json_path('0/id')
      expect(response.body).to have_json_path('0/name')
      expect(response.body).to have_json_path('0/request_id')
      expect(response.body).to have_json_path('0/transaction_id')
      expect(response.body).to have_json_path('0/status')
      expect(response.body).to have_json_path('0/order_items/0/item_id')
      expect(response.body).to have_json_path('0/order_items/0/name')
      expect(response.body).to have_json_path('0/order_items/0/quantity')
    end
  end
end
