require 'lita'
require 'pagerduty'

Lita.load_locales Dir[File.expand_path(
  File.join('..', '..', 'locales', '*.yml'), __FILE__
)]

require 'lita/handlers/pagerduty'

Lita::Handlers::Pagerduty.template_root File.expand_path(
  File.join('..', '..', 'templates'), __FILE__
)
