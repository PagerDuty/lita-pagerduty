# Lita-related code
module Lita
  # Plugin-related code
  module Handlers
    # Acknowledge-related routes
    class PagerdutyAck < Handler
      namespace 'Pagerduty'

      include ::PagerdutyHelper::Incident
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
        /^pager\sack\s(\w+)$/,
        :ack,
        command: true,
        help: {
          t('help.ack.syntax') => t('help.ack.desc')
        }
      )

      def ack_all(response)
        incidents = fetch_all_incidents
        if incidents.count > 0
          completed = []
          incidents.each do |incident|
            result = acknowledge_incident(incident.id)
            if result == "#{incident.id}: Incident acknowledged"
              completed.push(incident.id)
            end
            response.reply("Acknowledged: #{completed.join(',')}")
          end
        else
          response.reply(t('incident.none'))
        end
      end

      def ack_mine(response)
        email = redis.get("email_#{response.user.id}")
        if email
          incidents = fetch_my_incidents(email)
          if incidents.count > 0
            completed = []
            incidents.each do |incident|
              result = acknowledge_incident(incident.id)
              if result == "#{incident.id}: Incident acknowledged"
                completed.push(incident.id)
              end
              response.reply("Acknowledged: #{completed.join(',')}")
            end
          else
            response.reply(t('incident.none_mine'))
          end
        else
          response.reply(t('identify.missing'))
        end
      end

      def ack(response)
        incident_id = response.matches[0][0]
        return if incident_id == 'all' || incident_id == 'mine'
        response.reply(acknowledge_incident(incident_id))
      end
    end

    Lita.register_handler(PagerdutyAck)
  end
end
