# frozen_string_literal: true

module Commands
  class Ack
    include Base

    def call
      incident_id = message.match_data['incident_id']
      return if incident_id =~ /\A(all|mine)\z/i

      pagerduty.manage_incidents(:acknowledge, [incident_id])
      response message: 'all.acknowledged', params: { list: incident_id.to_s }
    rescue Exceptions::IncidentManageUnsuccess
      nil
    end
  end
end
