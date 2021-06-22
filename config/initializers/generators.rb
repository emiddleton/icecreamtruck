# frozen_string_literal: false

Rails.application.config.generators do |g|
  g.orm :active_record, primary_key_type: :uuid
end
