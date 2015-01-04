# Lita-related code
module Lita
  # Plugin-related code
  module Handlers
    # Resolve-related routes
    class PagerdutyResolve < Handler
      namespace 'Pagerduty'

      include ::PagerdutyHelper::Incident
      include ::PagerdutyHelper::Utility

      route(
        /^pager\sresolve\sall$/,
        :resolve_all,
        command: true,
        help: {
          t('help.resolve_all.syntax') => t('help.resolve_all.desc')
        }
      )

      route(
        /^pager\sresolve\smine$/,
        :resolve_mine,
        command: true,
        help: {
          t('help.resolve_mine.syntax') => t('help.resolve_mine.desc')
        }
      )

      route(
        /^pager\sresolve\s(\w+)$/,
        :resolve,
        command: true,
        help: {
          t('help.resolve.syntax') => t('help.resolve.desc')
        }
      )

      def resolve_all(response)
        incidents = fetch_all_incidents
        if incidents.count > 0
          completed = []
          incidents.each do |incident|
            result = resolve_incident(incident.id)
            if result == "#{incident.id}: Incident resolved"
              completed.push(incident.id)
            end
            response.reply("Resolved: #{completed.join(',')}")
          end
        else
          response.reply(t('incident.none'))
        end
      end

      def resolve_mine(response)
        email = redis.get("email_#{response.user.id}")
        if email
          incidents = fetch_my_incidents(email)
          if incidents.count > 0
            completed = []
            incidents.each do |incident|
              result = resolve_incident(incident.id)
              if result == "#{incident.id}: Incident resolved"
                completed.push(incident.id)
              end
              response.reply("Resolved: #{completed.join(',')}")
            end
          else
            response.reply(t('incident.none_mine'))
          end
        else
          response.reply(t('identify.missing'))
        end
      end

      def resolve(response)
        incident_id = response.matches[0][0]
        return if incident_id == 'all' || incident_id == 'mine'
        response.reply(resolve_incident(incident_id))
      end
    end

    Lita.register_handler(PagerdutyResolve)
  end
end
