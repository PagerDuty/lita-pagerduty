# Helper Code for PagerDuty Lita Handler
module PagerdutyHelper
  # Incident-related functions
  module Incident
    def format_incident(incident)
      t('incident.info', id: incident.id,
                         subject: incident.trigger_summary_data.subject,
                         url: incident.html_url,
                         assigned: incident.assigned_to_user.nil? ? 'none' : incident.assigned_to_user.email)
    end

    def resolve_incident(incident_id)
      incident = fetch_incident(incident_id)
      return t('incident.not_found', id: incident_id) if incident == 'No results'
      return t('incident.already_set', id: incident_id, status: incident.status) if incident.status == 'resolved'
      results = incident.resolve
      if results.key?('status') && results['status'] == 'resolved'
        t('incident.resolved', id: incident_id)
      else
        t('incident.unable_to_resolve', id: incident_id)
      end
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

    # rubocop:disable Metrics/AbcSize
    def acknowledge_incident(incident_id)
      incident = fetch_incident(incident_id)
      return t('incident.not_found', id: incident_id) if incident == 'No results'
      return t('incident.already_set', id: incident_id, status: incident.status) if incident.status == 'acknowledged'
      return t('incident.already_set', id: incident_id, status: incident.status) if incident.status == 'resolved'
      results = incident.acknowledge
      if results.key?('status') && results['status'] == 'acknowledged'
        t('incident.acknowledged', id: incident_id)
      else
        t('incident.unable_to_acknowledge', id: incident_id)
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end
