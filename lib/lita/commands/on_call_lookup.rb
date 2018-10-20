module Commands
  class OnCallLookup
    include Base

    def call
      response message: 'on_call_lookup.response', params: success_params
    rescue Exceptions::SchedulesEmptyList
      response message: 'on_call_lookup.no_matching_schedule',
               params: { schedule_name: schedule_name }
    rescue Exceptions::NoOncallUser
      response message: 'on_call_lookup.no_one_on_call',
               params: { schedule_name: schedule_name }
    end

    private

    def schedule
      @schedule ||= pagerduty.get_schedules(query: schedule_name).first
    end

    def schedule_name
      @schedule_name ||= message.match_data[1].strip
    end

    def oncall_user_params
      { 'schedule_ids[]' => schedule[:id], 'include[]' => 'users' }
    end

    def success_params
      {
        name: user[:summary],
        email: user[:email],
        schedule_name: schedule[:name]
      }
    end

    def user
      @user ||= pagerduty.get_oncall_user oncall_user_params
    end
  end
end
