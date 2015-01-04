# Helper Code for PagerDuty Lita Handler
module PagerdutyHelper
  # Utility functions
  module Regex
    INCIDENT_ID_PATTERN = /(?<incident_id>[a-zA-Z0-9+]{1,6})/
  end
end
