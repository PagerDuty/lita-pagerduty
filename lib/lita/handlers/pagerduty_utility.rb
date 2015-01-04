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
        /^who\'s\son\scall\?*$/,
        :whos_on_call,
        command: true,
        help: {
          t('help.whos_on_call.syntax') => t('help.whos_on_call.desc')
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

      def whos_on_call(response)
        response.reply(t('error.not_implemented'))
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
