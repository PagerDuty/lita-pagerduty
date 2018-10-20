require 'lita'
require 'exceptions'
require 'pagerduty'
require 'store'
require 'lita/handlers/pagerduty'
Dir[File.join(__dir__, 'lita', 'commands', '*.rb')].each { |file| require file }

Lita.load_locales Dir[File.expand_path(
  File.join('..', '..', 'locales', '*.yml'), __FILE__
)]

Lita::Handlers::Pagerduty.template_root File.expand_path(
  File.join('..', '..', 'templates'), __FILE__
)
