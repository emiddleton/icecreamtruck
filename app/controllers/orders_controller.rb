# frozen_string_literal: false

require 'pagy/extras/headers'

class OrdersController < ApplicationController
  # POST /orders
  def create
    order = Order.new(order_params)
    order.handle_payment!
    render json: order_json(order), status: :created
  end

  # GET /orders
  def index
    q = Order.includes(:order_items).joins(:order_items).ransack(params[:q])
    pagy, orders = pagy(q.result(distinct: true), items: 50)
    pagy_headers_merge(pagy)
    render json: order_json(orders), status: :ok
  end

  # PUT /orders/:id/complete
  def complete
    order = Order.find(params[:id])
    order.complete_sale!
    head :no_content
  end

  # PUT /orders/:id/cancel
  def cancel
    order = Order.find(params[:id])
    order.cancel!
    render json: order_json(order), status: :ok
  end

  private

  def order_json(order)
    order.to_json(include: { order_items: { only: %i[name item_id quantity] } })
  end

  def order_params
    params.require(:order).tap do |p|
      p[:order_items_attributes] = p.delete(:order_items)
    end.permit(:name, :request_id, order_items_attributes: %i[item_id quantity],
                                   payment: %i[card_number expiry_date])
  end
end
