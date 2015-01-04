# Lita-related code
module Lita
  # Plugin-related code
  module Handlers
    # Main routes
    class Pagerduty < Handler
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

      route(
        /^pager\snotes\s(\w+)$/,
        :notes,
        command: true,
        help: {
          t('help.notes.syntax') => t('help.notes.desc')
        }
      )

      route(
        /^pager\snote\s(\w+)\s(.+)$/,
        :note,
        command: true,
        help: {
          t('help.note.syntax') => t('help.note.desc')
        }
      )

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

      def self.default_config(config)
        config.api_key = nil
        config.subdomain = nil
      end

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
          response.reply(t('incident.not_found', id: incident_id))
        end
      end

      def note(response)
        response.reply(t('error.not_implemented'))
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

    Lita.register_handler(Pagerduty)
  end
end
