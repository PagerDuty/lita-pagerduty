require 'simplecov'
require 'coveralls'
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start { add_filter '/spec/' }

require 'lita-pagerduty'
require 'lita/rspec'

Lita.version_3_compatibility_mode = false

RSpec.configure do |config|
  config.before do
    registry.register_handler(Lita::Handlers::PagerdutyAck)
    registry.register_handler(Lita::Handlers::PagerdutyIncident)
    registry.register_handler(Lita::Handlers::PagerdutyNote)
    registry.register_handler(Lita::Handlers::PagerdutyResolve)
    registry.register_handler(Lita::Handlers::PagerdutyUtility)
  end
end
