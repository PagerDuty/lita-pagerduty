module Commands
  class Incident
    include Base

    def call
      incident_id = message.match_data['incident_id']
      incident = pagerduty.get_incident(incident_id)
      response format_incidents([incident])
    rescue Exceptions::IncidentNotFound
      response message: 'incident.not_found', params: { id: incident_id }
    end
  end
end
