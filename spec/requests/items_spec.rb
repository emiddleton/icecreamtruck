# frozen_string_literal: false

require 'rails_helper'
require 'request_helper'

RSpec.describe 'Scores', type: :request do
  include_context 'json'
  include_context 'items'

  describe 'GET /items' do
    it 'should return a list of registered items.' do
      get_json '/items'

      expect(response.body).to be_json_eql(%(
        [
          { "name": "Chocolate",  "price": 100, "quantity": 200 },
          { "name": "Pistachio",  "price": 120, "quantity": 100 },
          { "name": "Strawberry", "price": 100, "quantity": 200 },
          { "name": "Mint",       "price": 100, "quantity": 100 }
        ]

      ))
    end
  end

  describe 'GET /sales' do
    it 'should return a list of the items with sales data' do
      get_json '/sales'

      expect(response.body).to be_json_eql(%(
        [
          { "name": "Chocolate",  "price": 100, "quantity": 200, "sales": 5000 },
          { "name": "Pistachio",  "price": 120, "quantity": 100, "sales": 3000 },
          { "name": "Strawberry", "price": 100, "quantity": 200, "sales": 5000 },
          { "name": "Mint",       "price": 100, "quantity": 100, "sales": 2000 }
        ]
      ))
    end
  end
end
