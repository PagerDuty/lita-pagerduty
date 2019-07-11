# frozen_string_literal: true

module Commands
  class AckMine
    include Base

    def call
      ids = pagerduty.get_incidents(query_params).map { |i| i[:id] }
      pagerduty.manage_incidents(:acknowledge, ids)
      response message: 'all.acknowledged', params: { list: ids.join(', ') }
    rescue Exceptions::UserNotIdentified
      response message: 'incident.none_mine'
    rescue Exceptions::IncidentsEmptyList
      response message: 'incident.none_mine'
    rescue Exceptions::IncidentManageUnsuccess
      nil
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
