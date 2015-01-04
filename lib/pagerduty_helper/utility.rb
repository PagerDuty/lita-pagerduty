# Helper Code for PagerDuty Lita Handler
module PagerdutyHelper
  # Utility functions
  module Utility
    def pd_client
      if Lita.config.handlers.pagerduty.api_key.nil? ||
         Lita.config.handlers.pagerduty.subdomain.nil?
        fail 'Bad config'
      end

      ::Pagerduty.new(token: Lita.config.handlers.pagerduty.api_key,
                      subdomain: Lita.config.handlers.pagerduty.subdomain)
    end
  end
end
