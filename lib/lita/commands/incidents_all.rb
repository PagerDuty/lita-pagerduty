module Commands
  class IncidentsAll
    include Base

    def call
      incidents = pagerduty.get_incidents(query_params)
      response format_incidents(incidents)
    rescue Exceptions::IncidentsEmptyList
      response message: 'incident.none'
    end

    private

    def query_params
      { statuses: %w[triggered acknowledged] }
    end
  end
end
