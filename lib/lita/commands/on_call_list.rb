module Commands
  class OnCallList
    include Base

    def call
      schedules = pagerduty.get_schedules.map { |i| i[:name] }.join("\n")
      response message: 'on_call_list.response',
               params: { schedules: schedules }
    rescue Exceptions::SchedulesEmptyList
      response message: 'on_call_list.no_schedules_found'
    end
  end
end
