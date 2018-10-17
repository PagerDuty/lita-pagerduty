require 'simplecov'
require 'coveralls'
SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start { add_filter '/spec/' }

require 'lita-pagerduty'
require 'lita/rspec'
Lita.version_3_compatibility_mode = false

RSpec.configure do |config|
  config.before do
    Lita.config.handlers.pagerduty.api_key = 'foo'
    Lita.config.handlers.pagerduty.email = 'foo@pagerduty.com'
    Lita.config.redis[:host] = ENV['REDIS_HOST'] if ENV['REDIS_HOST']
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.default_formatter = 'doc' if config.files_to_run.one?
  config.order = :random
  Kernel.srand config.seed
end
