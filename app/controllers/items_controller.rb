# frozen_string_literal: false

require 'pagy/extras/headers'

class ItemsController < ApplicationController
  # GET /items
  def index
    @q = Item.ransack(params[:q])
    @pagy, @items = pagy(@q.result(distinct: true), items: 50)
    pagy_headers_merge(@pagy)
    render json: @items.to_json(only: %i[id name price quantity]), status: :ok
  end

  # GET /sales
  def sales
    @q = Item.ransack(params[:q])
    @pagy, @items = pagy(@q.result(distinct: true), items: 50)
    pagy_headers_merge(@pagy)
    render json: @items, status: :ok
  end
end
