# Lita-related code
module Lita
  # Plugin-related code
  module Handlers
    # Note-related routes
    class PagerdutyNote < Handler
      namespace 'Pagerduty'

      include ::PagerdutyHelper::Incident
      include ::PagerdutyHelper::Regex
      include ::PagerdutyHelper::Utility

      route(
        /^pager\snotes\s#{INCIDENT_ID_PATTERN}$/,
        :notes,
        command: true,
        help: {
          t('help.notes.syntax') => t('help.notes.desc')
        }
      )

      route(
        /^pager\snote\s#{INCIDENT_ID_PATTERN}\s(.+)$/,
        :note,
        command: true,
        help: {
          t('help.note.syntax') => t('help.note.desc')
        }
      )

      def notes(response)
        incident_id = response.match_data['incident_id']
        incident = fetch_incident(incident_id)
        return response.reply(t('incident.not_found', id: incident_id)) if incident == 'No results'
        return response.reply("#{incident_id}: No notes") unless incident.notes.notes.count > 0
        incident.notes.notes.each do |note|
          response.reply(format_note(incident, note))
        end
      end

      def note(response)
        response.reply(t('error.not_implemented'))
      end
    end

    Lita.register_handler(PagerdutyNote)
  end
end
