# frozen_string_literal: false

class ApplicationController < ActionController::API
  include Pagy::Backend
  include ExceptionHandler
end
