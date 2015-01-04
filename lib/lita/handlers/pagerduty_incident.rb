# Lita-related code
module Lita
  # Plugin-related code
  module Handlers
    # Incident-related routes
    class PagerdutyIncident < Handler
      namespace 'Pagerduty'

      include ::PagerdutyHelper::Incident
      include ::PagerdutyHelper::Regex
      include ::PagerdutyHelper::Utility

      route(
        /^pager\sincidents\sall$/,
        :incidents_all,
        command: true,
        help: {
          t('help.incidents_all.syntax') => t('help.incidents_all.desc')
        }
      )

      route(
        /^pager\sincidents\smine$/,
        :incidents_mine,
        command: true,
        help: {
          t('help.incidents_mine.syntax') => t('help.incidents_mine.desc')
        }
      )

      route(
        /^pager\sincident\s#{INCIDENT_ID_PATTERN}$/,
        :incident,
        command: true,
        help: {
          t('help.incident.syntax') => t('help.incident.desc')
        }
      )

      def incidents_all(response)
        incidents = fetch_all_incidents
        return response.reply(t('incident.none')) unless incidents.count > 0
        incidents.each do |incident|
          response.reply(format_incident(incident))
        end
      end

      def incidents_mine(response)
        email = fetch_user(response.user)
        return response.reply(t('identify.missing')) unless email
        incidents = fetch_my_incidents(email)
        response.reply(t('incident.none_mine')) unless incidents.count > 0
        incidents.each do |incident|
          response.reply(format_incident(incident))
        end
      end

      def incident(response)
        incident_id = response.match_data['incident_id']
        incident = fetch_incident(incident_id)
        return response.reply(t('incident.not_found', id: incident_id)) if incident == 'No results'
        response.reply(format_incident(incident))
      end
    end

    Lita.register_handler(PagerdutyIncident)
  end
end
