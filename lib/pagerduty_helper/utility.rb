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

    def store_user(user, email)
      redis.set(format_user(user), email)
    end

    def fetch_user(user)
      redis.get(format_user(user))
    end

    def delete_user(user)
      redis.del(format_user(user))
    end

    def format_user(user)
      "email_#{user.id}"
    end
  end
end
