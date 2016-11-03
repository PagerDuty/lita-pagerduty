require 'time'

# Lita-related code
module Lita
  # Plugin-related code
  module Handlers
    # Utility-ish routes
    class PagerdutyUtility < Handler
      config :api_key, required: true
      config :subdomain, required: true

      namespace 'Pagerduty'

      include ::PagerdutyHelper::Incident
      include ::PagerdutyHelper::Regex
      include ::PagerdutyHelper::Utility

      route(
        /^pager\soncall$/,
        :on_call_list,
        command: true,
        help: {
          t('help.on_call_list.syntax') => t('help.on_call_list.desc')
        }
      )

      route(
        /^pager\soncall\s(.*)$/,
        :on_call_lookup,
        command: true,
        help: {
          t('help.on_call_lookup.syntax') => t('help.on_call_lookup.desc')
        }
      )

      route(
        /^pager\sidentify\s#{EMAIL_PATTERN}$/,
        :identify,
        command: true,
        help: {
          t('help.identify.syntax') => t('help.identify.desc')
        }
      )

      route(
        /^pager\sforget$/,
        :forget,
        command: true,
        help: {
          t('help.forget.syntax') => t('help.forget.desc')
        }
      )

      route(
        /^pager\swhoami$/,
        :whoami,
        command: true,
        help: {
          t('help.whoami.syntax') => t('help.whoami.desc')
        }
      )

      route(
        /^pager\s+me\s+(.+?)\s+(\d+)m?$/,
        :pager_me,
        command: true,
        help: { t('help.pager_me.syntax') => t('help.pager_me.desc') }
      )

      def on_call_list(response)
        schedules = pd_client.get_schedules.schedules
        if schedules.any?
          schedule_list = schedules.map(&:name).join("\n")
          response.reply(t('on_call_list.response', schedules: schedule_list))
        else
          response.reply(t('on_call_list.no_schedules_found'))
        end
      end

      # rubocop:disable Metrics/AbcSize
      def on_call_lookup(response)
        schedule_name = response.match_data[1].strip
        schedule = pd_client.get_schedules.schedules.find { |s| s.name.casecmp(schedule_name) == 0 }

        unless schedule
          return response.reply(t('on_call_lookup.no_matching_schedule', schedule_name: schedule_name))
        end

        if (user = lookup_on_call_user(schedule.id))
          response.reply(t('on_call_lookup.response', name: user.name, email: user.email, schedule_name: schedule_name))
        else
          response.reply(t('on_call_lookup.no_one_on_call', schedule_name: schedule_name))
        end
      end
      # rubocop:enable Metrics/AbcSize

      # rubocop:disable Metrics/AbcSize
      def pager_me(response)
        schedule_name = response.match_data[1].strip
        schedule = pd_client.get_schedules.schedules.find { |s| s.name.casecmp(schedule_name) == 0 }
        return response.reply(t('on_call_lookup.no_matching_schedule', schedule_name: schedule_name)) unless schedule

        email = fetch_user(response.user)
        return response.reply(t('identify.missing')) unless email

        users = pd_client.get_users(query: email)
        return response.reply(t('identify.unrecognised')) unless users.total == 1

        override = take_pager(schedule.id, users.users.first.id, response.match_data[2].strip.to_i)
        return response.reply(t('pager_me.failure')) unless override

        response.reply(t('pager_me.success', name: override.user.name, email: override.user.email, finish: override.end))
      end
      # rubocop:enable Metrics/AbcSize

      def identify(response)
        email = response.match_data['email']
        stored_email = fetch_user(response.user)
        return response.reply(t('identify.already')) if stored_email
        store_user(response.user, email)
        response.reply(t('identify.complete'))
      end

      def forget(response)
        stored_email = fetch_user(response.user)
        return response.reply(t('forget.unknown')) unless stored_email
        delete_user(response.user)
        response.reply(t('forget.complete'))
      end

      def whoami(response)
        user = fetch_user(response.user)
        return response.reply(t('whoami.unknown')) if user.nil?
        response.reply(t('whoami.known', email: user))
      end

      private

      def lookup_on_call_user(schedule_id)
        now = ::Time.now.utc
        pd_client.get_schedule_users(
          id: schedule_id,
          since: now.iso8601,
          until: (now + 3600).iso8601
        ).first
      end
    end

    Lita.register_handler(PagerdutyUtility)
  end
end
