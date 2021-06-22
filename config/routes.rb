# frozen_string_literal: false

Rails.application.routes.draw do
  resources :orders, only: %i[index create] do
    member do
      put :cancel
      put :complete
    end
  end

  get 'items', to: 'items#index'
  get 'sales', to: 'items#sales'
end
