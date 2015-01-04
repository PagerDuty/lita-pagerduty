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
      include ::PagerdutyHelper::Utility

      route(
        /^who\'s\son\scall\?*$/,
        :whos_on_call,
        command: true,
        help: {
          t('help.whos_on_call.syntax') => t('help.whos_on_call.desc')
        }
      )

      route(
        /^pager\sidentify\s(.+)$/,
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

      def whos_on_call(response)
        response.reply(t('error.not_implemented'))
      end

      def identify(response)
        email = response.matches[0][0]
        stored_email = redis.get("email_#{response.user.id}")
        if !stored_email
          redis.set("email_#{response.user.id}", email)
          response.reply(t('identify.complete'))
        else
          response.reply(t('identify.already'))
        end
      end

      def forget(response)
        stored_email = redis.get("email_#{response.user.id}")
        if stored_email
          redis.del("email_#{response.user.id}")
          response.reply(t('forget.complete'))
        else
          response.reply(t('forget.unknown'))
        end
      end
    end

    Lita.register_handler(PagerdutyUtility)
  end
end
