module Commands
  class PagerMe
    include Base

    def call
      response message: 'pager_me.success', params: success_response_params
    rescue Exceptions::SchedulesEmptyList
      response schedules_empty_list
    rescue Exceptions::UserNotIdentified
      response message: 'identify.missing'
    rescue Exceptions::UsersEmptyList
      response message: 'identify.unrecognised'
    rescue Exceptions::OverrideUnsuccess
      response message: 'pager_me.failure'
    end

    private

    def schedules_empty_list
      {
        message: 'on_call_lookup.no_matching_schedule',
        params: {
          schedule_name: message.match_data[1].strip
        }
      }
    end

    def schedule
      @schedule ||= pagerduty.get_schedules(
        query: message.match_data[1].strip
      ).first
    end

    def override
      @override ||= pagerduty.override(
        schedule[:id], current_user[:id], message.match_data[2].strip.to_i
      )
    end

    def success_response_params
      {
        name: override[:user][:summary],
        email: current_user[:email],
        finish: override[:end]
      }
    end
  end
end
