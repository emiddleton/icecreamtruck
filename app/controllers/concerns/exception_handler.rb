# frozen_string_literal: false

module ExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound do |e|
      render json: { message: e.message }, status: :not_found
    end

    rescue_from PG::UniqueViolation do |e|
      raise unless e.message.include?('index_unique_order')

      # the same score has been posted more then once
      render json: { message: 'This order has already been received.' }, status: :conflict
    end

    rescue_from PaymentException do |e|
      render json: { message: e.message }, status: :unprocessable_entity
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      render json: { message: e.message }, status: :unprocessable_entity
    end
  end
end
