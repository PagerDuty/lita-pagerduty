# frozen_string_literal: true

module Commands
  class AckAll
    include Base

    def call
      ids = pagerduty.get_incidents(query_params).map { |i| i[:id] }
      pagerduty.manage_incidents(:acknowledge, ids)
      response message: 'all.acknowledged', params: { list: ids.join(', ') }
    rescue Exceptions::IncidentsEmptyList
      response message: 'incident.none'
    rescue Exceptions::IncidentManageUnsuccess
      nil
    end

    private

    def query_params
      { statuses: %w[triggered acknowledged] }
    end
  end
end
