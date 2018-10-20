module Commands
  class Notes
    include Base

    def call
      incident_id = message.match_data['incident_id']
      notes = pagerduty.get_notes_by_incident_id(incident_id)
      response format_notes(notes, incident_id)
    rescue Exceptions::IncidentNotFound
      response message: 'incident.not_found', params: { id: incident_id }
    rescue Exceptions::NotesEmptyList
      response "#{incident_id}: No notes"
    end
  end
end
