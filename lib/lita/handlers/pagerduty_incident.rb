# Lita-related code
module Lita
  # Plugin-related code
  module Handlers
    # Incident-related routes
    class PagerdutyIncident < Handler
      namespace 'Pagerduty'

      include ::PagerdutyHelper::Incident
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
        /^pager\sincident\s(\w+)$/,
        :incident,
        command: true,
        help: {
          t('help.incident.syntax') => t('help.incident.desc')
        }
      )

      def incidents_all(response)
        incidents = fetch_all_incidents
        if incidents.count > 0
          incidents.each do |incident|
            response.reply("#{incident.id}: " \
                           "\"#{incident.trigger_summary_data.subject}\", " \
                           "assigned to: #{incident.assigned_to_user.email}")
          end
        else
          response.reply(t('incident.none'))
        end
      end

      def incidents_mine(response)
        email = redis.get("email_#{response.user.id}")
        if email
          incidents = fetch_my_incidents(email)
          if incidents.count > 0
            incidents.each do |incident|
              response.reply("#{incident.id}: " \
                             "\"#{incident.trigger_summary_data.subject}\", " \
                             "assigned to: #{incident.assigned_to_user.email}")
            end
          else
            response.reply(t('incident.none_mine'))
          end
        else
          response.reply(t('identify.missing'))
        end
      end

      def incident(response)
        incident_id = response.matches[0][0]
        incident = fetch_incident(incident_id)
        if incident != 'No results'
          response.reply("#{incident_id}: " \
                         "\"#{incident.trigger_summary_data.subject}\", " \
                         "assigned to: #{incident.assigned_to_user.email}")
        else
          response.reply(t('incident.not_found', id: incident_id))
        end
      end
    end

    Lita.register_handler(PagerdutyIncident)
  end
end
