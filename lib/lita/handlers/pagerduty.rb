# Lita-related code
module Lita
  # Plugin-related code
  module Handlers
    # Lita Config values
    class Pagerduty < Handler
      config :api_key, required: true
      config :subdomain, required: true
      config :topic_frequency, type: Integer, default: 300
      config :topic_rooms, type: Hash, default: {}
    end

    Lita.register_handler(Pagerduty)
  end
end
