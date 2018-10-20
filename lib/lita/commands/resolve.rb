module Commands
  class Resolve
    include Base

    def call
      incident_id = message.match_data['incident_id']
      return if incident_id =~ /\A(all|mine)\z/i
      pagerduty.manage_incidents(:resolve, [incident_id])
      response message: 'all.resolved', params: { list: incident_id.to_s }
    rescue Exceptions::IncidentManageUnsuccess
      nil
    end
  end
end
