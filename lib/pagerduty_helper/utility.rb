require 'time'

# Helper Code for PagerDuty Lita Handler
module PagerdutyHelper
  # Utility functions
  module Utility
    USER_PREFIX = 'email_'.freeze

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

    def fetch_user_by_email(email)
      user_id = nil

      redis.keys(USER_PREFIX + '*').each do |k|
        if redis.get(k) == email
          user_id = k.sub(USER_PREFIX, '')
        end
      end

      user_id
    end

    def delete_user(user)
      redis.del(format_user(user))
    end

    def format_user(user)
      "#{USER_PREFIX}#{user.id}"
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

    def lookup_on_call_user(schedule_id)
      now = ::Time.now.utc
      pd_client.get_schedule_users(
        id: schedule_id,
        since: now.iso8601,
        until: (now + 3600).iso8601
      ).first
    end

    def schedule_by_name(schedule_name)
      pd_client.get_schedules.schedules.find { |s| s.name.casecmp(schedule_name).zero? }
    end
  end
end
