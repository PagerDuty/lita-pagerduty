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

    def take_pager(schedule_id, user_id, duration_mins)
      from = ::Time.now.utc + 10
      to = from + (60 * duration_mins)

      pd_client.create_schedule_override(
        id: schedule_id,
        override: {
          user_id: user_id,
          start: from.iso8601,
          end: to.iso8601
        }
      )
    end
  end
end
