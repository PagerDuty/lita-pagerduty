# Helper Code for PagerDuty Lita Handler
module PagerdutyHelper
  # Utility functions
  module Utility
    def pd_client
      ::Pagerduty.new(token: config.api_key, subdomain: config.subdomain)
    end
  end
end
