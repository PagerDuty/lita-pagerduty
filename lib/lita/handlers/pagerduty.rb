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

      route(
        /^pager\sidentify\s(.+)$/,
        :identify,
        command: true,
        help: {
          'pager identify <email address>' =>
          'Associate your chat user with your email address'
        }
      )

      route(
        /^pager\sforget$/,
        :forget,
        command: true,
        help: {
          'pager forget' => 'Remove your chat user / email association'
        }
      )

      def self.default_config(config)
        config.api_key = nil
        config.subdomain = nil
      end

      def whos_on_call(response)
        response.reply('broken')
      end

      def identify(response)
        email = response.matches[0][0]
        stored_email = redis.get("email_#{response.user.id}")
        if !stored_email
          redis.set("email_#{response.user.id}", email)
          response.reply('You have now been identified.')
        else
          response.reply('You have already been identified!')
        end
      end

      def forget(response)
        stored_email = redis.get("email_#{response.user.id}")
        if stored_email
          redis.del("email_#{response.user.id}")
          response.reply('Your email has now been forgotten.')
        else
          response.reply('No email on record for you.')
        end
      end

      def incidents_all(response)
        incidents = fetch_all_incidents
        if incidents.count > 0
          incidents.each do |incident|
            response.reply("#{incident.id}: " \
                           "\"#{incident.trigger_summary_data.subject}\", " \
                           "assigned to: #{incident.assigned_to_user.email}")
          end
        else
          response.reply('No triggered, open, or acknowledged incidents')
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
            response.reply('You have no triggered, open, or acknowledged ' \
                           'incidents')
          end
        else
          response.reply('You have not identified yourself (use the help ' \
                         'command for more info)')
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
        incidents = fetch_all_incidents
        if incidents.count > 0
          completed = []
          incidents.each do |incident|
            result = acknowledge_incident(incident.id)
            if result == "#{incident.id}: Incident acknowledged"
              completed.push(incident.id)
            end
            response.reply("Acknowledged: #{completed.join(",")}")
          end
        else
          response.reply('No triggered, open, or acknowledged incidents')
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
              response.reply("Acknowledged: #{completed.join(",")}")
            end
          else
            response.reply('You have no triggered, open, or acknowledged ' \
                           'incidents')
          end
        else
          response.reply('You have not identified yourself (use the help ' \
                         'command for more info)')
        end
      end

      def ack(response)
        incident_id = response.matches[0][0]
        return if incident_id == 'all' || incident_id == 'mine'
        response.reply(acknowledge_incident(incident_id))
      end

      def resolve_all(response)
        incidents = fetch_all_incidents
        if incidents.count > 0
          completed = []
          incidents.each do |incident|
            result = resolve_incident(incident.id)
            if result == "#{incident.id}: Incident resolved"
              completed.push(incident.id)
            end
            response.reply("Resolved: #{completed.join(",")}")
          end
        else
          response.reply('No triggered, open, or acknowledged incidents')
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
              response.reply("Resolved: #{completed.join(",")}")
            end
          else
            response.reply('You have no triggered, open, or acknowledged ' \
                           'incidents')
          end
        else
          response.reply('You have not identified yourself (use the help ' \
                         'command for more info)')
        end
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

      def fetch_all_incidents
        client = pd_client
        list = []
        # FIXME: Workaround on current PD Gem
        client.incidents.incidents.each do |incident|
          list.push(incident) if incident.status != 'resolved'
        end
        list
      end

      def fetch_my_incidents(email)
        # FIXME: Workaround
        incidents = fetch_all_incidents
        list = []
        incidents.each do |incident|
          list.push(incident) if incident.assigned_to_user.email == email
        end
        list
      end

      def fetch_incident(incident_id)
        client = pd_client
        client.get_incident(id: incident_id)
      end

      def acknowledge_incident(incident_id)
        incident = fetch_incident(incident_id)
        if incident != 'No results'
          if incident.status != 'acknowledged' &&
             incident.status != 'resolved'
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
