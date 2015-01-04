# Lita-related code
module Lita
  # Plugin-related code
  module Handlers
    # Acknowledge-related routes
    class PagerdutyAck < Handler
      namespace 'Pagerduty'

      include ::PagerdutyHelper::Incident
      include ::PagerdutyHelper::Regex
      include ::PagerdutyHelper::Utility

      route(
        /^pager\sack\sall$/,
        :ack_all,
        command: true,
        help: {
          t('help.ack_all.syntax') => t('help.ack_all.desc')
        }
      )

      route(
        /^pager\sack\smine$/,
        :ack_mine,
        command: true,
        help: {
          t('help.ack_mine.syntax') => t('help.ack_mine.desc')
        }
      )

      route(
        /^pager\sack\s#{INCIDENT_ID_PATTERN}$/,
        :ack,
        command: true,
        help: {
          t('help.ack.syntax') => t('help.ack.desc')
        }
      )

      def ack_all(response)
        incidents = fetch_all_incidents
        return response.reply(t('incident.none')) unless incidents.count > 0
        completed = []
        incidents.each do |incident|
          result = acknowledge_incident(incident.id)
          completed.push(incident.id) if result == "#{incident.id}: Incident acknowledged"
          response.reply(t('all.acknowledged', list: completed.join(', ')))
        end
      end

      def ack_mine(response)
        email = fetch_user(response.user)
        return response.reply(t('identify.missing')) unless email
        incidents = fetch_my_incidents(email)
        return response.reply(t('incident.none_mine')) unless incidents.count > 0
        completed = []
        incidents.each do |incident|
          result = acknowledge_incident(incident.id)
          completed.push(incident.id) if result == "#{incident.id}: Incident acknowledged"
          response.reply(t('all.acknowledged', list: completed.join(', ')))
        end
      end

      def ack(response)
        incident_id = response.match_data['incident_id']
        return if incident_id == 'all' || incident_id == 'mine'
        response.reply(acknowledge_incident(incident_id))
      end
    end

    Lita.register_handler(PagerdutyAck)
  end
end
