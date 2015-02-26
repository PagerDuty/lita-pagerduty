require 'lita'

Lita.load_locales Dir[File.expand_path(
  File.join('..', '..', 'locales', '*.yml'), __FILE__
)]

require 'pagerduty'

require 'pagerduty_helper/incident'
require 'pagerduty_helper/regex'
require 'pagerduty_helper/utility'

require 'lita/handlers/pagerduty_ack'
require 'lita/handlers/pagerduty_incident'
require 'lita/handlers/pagerduty_note'
require 'lita/handlers/pagerduty_resolve'
require 'lita/handlers/pagerduty_utility'
