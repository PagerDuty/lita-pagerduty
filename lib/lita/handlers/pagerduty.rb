require "lita"

module Lita
  module Handlers
    class Pagerduty < Handler
    end

    Lita.register_handler(Pagerduty)
  end
end

Lita.load_locales Dir[File.expand_path(
  File.join("..", "..", "..", "..", "locales", "*.yml"), __FILE__
)]
