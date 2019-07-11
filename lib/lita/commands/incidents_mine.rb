# frozen_string_literal: true

module Commands
  class IncidentsMine
    include Base

    def call
      incidents = pagerduty.get_incidents(query_params)
      response format_incidents(incidents)
    rescue Exceptions::IncidentsEmptyList
      response message: 'incident.none'
    rescue Exceptions::UserNotIdentified
      response message: 'incident.none_mine'
    end

    private

    def query_params
      {
        statuses: %w[triggered acknowledged],
        'user_ids[]' => current_user[:id]
      }
    end
  end
end
