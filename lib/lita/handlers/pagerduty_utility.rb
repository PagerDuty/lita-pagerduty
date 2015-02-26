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

      def on_call_list(response)
        schedules = pd_client.get_schedules.schedules
        response.reply("Available schedules: #{schedules.map(&:name).join(', ')}")
      end

      def on_call_lookup(response)
        schedule_name = response.match_data[1].strip
        schedule = pd_client.get_schedules.schedules.find { |s| s.name == schedule_name }

        unless schedule
          return response.reply("No matching schedule found for '#{schedule_name}'")
        end

        now = Time.now.utc
        user = pd_client.get_schedule_users(
          id: schedule.id,
          since: now.iso8601,
          until: (now + 3600).iso8601
        ).first

        if user
          response.reply("#{user.name} (#{user.email}) is currently on call for #{schedule_name}")
        else
          response.reply("No one is currently on call for #{schedule_name}")
        end
      end

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
    end

    Lita.register_handler(PagerdutyUtility)
  end
end
