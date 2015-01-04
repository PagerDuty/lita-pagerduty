# Helper Code for PagerDuty Lita Handler
module PagerdutyHelper
  # Utility functions
  module Utility
    def pd_client
      ::Pagerduty.new(token: config.api_key, subdomain: config.subdomain)
    end

    def format_note(incident, note)
      t('note.show', id: incident.id, content: note.content, email: note.user.email)
    end
  end
end
