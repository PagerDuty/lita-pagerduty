require 'lita'
require 'pagerduty'

module Lita
  module Handlers
    class Pagerduty < Handler
      route(
        /^who\'s\son\scall\?*$/,
        :whos_on_call,
        command: true,
        help: {
          'who\'s on call?' => 'Return the names of everyone currently on call'
        }
      )

      route(
        /^pager\sincidents\sall$/,
        :incidents_all,
        command: true,
        help: {
          'pager incidents all' => 'Show all open incidents'
        }
      )

      route(
        /^pager\sincidents\smine$/,
        :incidents_mine,
        command: true,
        help: {
          'pager incidents mine' => 'Show all open incidents assigned to me'
        }
      )

      route(
        /^pager\sincident\s(\w+)$/,
        :incident,
        command: true,
        help: {
          'pager incident 1234' => 'Show a specific incident'
        }
      )

      route(
        /^pager\snotes\s(\w+)$/,
        :notes,
        command: true,
        help: {
          'pager notes 1234' => 'Show all notes for a specific incident'
        }
      )

      route(
        /^pager\snote\s(\w+)\s(.+)$/,
        :note,
        command: true,
        help: {
          'pager note 1234 some text' => 'Add a note to a specific incident'
        }
      )

      route(
        /^pager\sack\sall$/,
        :ack_all,
        command: true,
        help: {
          'pager ack all' => 'Acknowledge all triggered incidents'
        }
      )

      route(
        /^pager\sack\smine$/,
        :ack_mine,
        command: true,
        help: {
          'pager ack mine' =>
          'Acknowledge all triggered incidents assigned to me'
        }
      )

      route(
        /^pager\sack\s(\w+)$/,
        :ack,
        command: true,
        help: {
          'pager ack 1234' => 'Acknowledge a specific incident'
        }
      )

      route(
        /^pager\sresolve\sall$/,
        :resolve_all,
        command: true,
        help: {
          'pager resolve all' => 'Resolve all triggered incidents'
        }
      )

      route(
        /^pager\sresolve\smine$/,
        :resolve_mine,
        command: true,
        help: {
          'pager resolve mine' =>
          'Resolve all triggered incidents assigned to me'
        }
      )

      route(
        /^pager\sresolve\s(\w+)$/,
        :resolve,
        command: true,
        help: {
          'pager resolve 1234' => 'Resolve a specific incident'
        }
      )

      def self.default_config(config)
        config.api_key = nil
        config.subdomain = nil
      end

      def whos_on_call(response)
        response.reply('broken')
      end

      def incidents_all(response)
        response.reply('broken')
      end

      def incidents_mine(response)
        response.reply('broken')
      end

      def incident(response)
        incident_id = response.matches[0][0]
        incident = fetch_incident(incident_id)
        if incident != 'No results'
          response.reply("#{incident_id}: " \
                         "\"#{incident.trigger_summary_data.subject}\", " \
                         "assigned to: #{incident.assigned_to_user.email}")
        else
          response.reply("#{incident_id}: Incident not found")
        end
      end

      def notes(response)
        incident_id = response.matches[0][0]
        incident = fetch_incident(incident_id)
        if incident != 'No results'
          if incident.notes.notes.count > 0
            incident.notes.notes.each do |note|
              response.reply("#{incident_id}: #{note.content} "\
                             "(#{note.user.email})")
            end
          else
            response.reply("#{incident_id}: No notes")
          end
        else
          response.reply("#{incident_id}: Incident not found")
        end
      end

      def note(response)
        response.reply('broken')
      end

      def ack_all(response)
        response.reply('broken')
      end

      def ack_mine(response)
        response.reply('broken')
      end

      def ack(response)
        incident_id = response.matches[0][0]
        return if incident_id == 'all' || incident_id == 'mine'
        response.reply(acknowledge_incident(incident_id))
      end

      def resolve_all(response)
        response.reply('broken')
      end

      def resolve_mine(response)
        response.reply('broken')
      end

      def resolve(response)
        incident_id = response.matches[0][0]
        return if incident_id == 'all' || incident_id == 'mine'
        response.reply(resolve_incident(incident_id))
      end

      private

      def pd_client
        if Lita.config.handlers.pagerduty.api_key.nil? ||
           Lita.config.handlers.pagerduty.subdomain.nil?
          fail 'Bad config'
        end

        ::Pagerduty.new(token: Lita.config.handlers.pagerduty.api_key,
                        subdomain: Lita.config.handlers.pagerduty.subdomain)
      end

      def fetch_incident(incident_id)
        client = pd_client
        client.get_incident(id: incident_id)
      end

      def acknowledge_incident(incident_id)
        incident = fetch_incident(incident_id)
        if incident != 'No results'
          if incident.status != 'acknowledged'
            results = incident.acknowledge
            if results.key?('status') && results['status'] == 'acknowledged'
              "#{incident_id}: Incident acknowledged"
            else
              "#{incident_id}: Unable to acknowledge incident"
            end
          else
            "#{incident_id}: Incident already #{incident.status}"
          end
        else
          "#{incident_id}: Incident not found"
        end
      end

      def resolve_incident(incident_id)
        incident = fetch_incident(incident_id)
        if incident != 'No results'
          if incident.status != 'resolved'
            results = incident.resolve
            if results.key?('status') && results['status'] == 'resolved'
              "#{incident_id}: Incident resolved"
            else
              "#{incident_id}: Unable to resolve incident"
            end
          else
            "#{incident_id}: Incident already #{incident.status}"
          end
        else
          "#{incident_id}: Incident not found"
        end
      end
    end

    Lita.register_handler(Pagerduty)
  end
end
