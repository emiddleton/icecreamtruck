# frozen_string_literal: false

class ApplicationController < ActionController::API
  include Pagy::Backend
  include Pagy::Frontend
  include ExceptionHandler
end
