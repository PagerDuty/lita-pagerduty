module Commands
  class BaseLookup
    include Base

    def call
      response message: 'base_lookup.response', params: success_params
    rescue Exceptions::SchedulesEmptyList
      response message: 'base_lookup.no_matching_schedule',
               params: { schedule_name: schedule_name }
    rescue Exceptions::NoOncallUser
      response message: 'base_lookup.no_one_on_call',
               params: { schedule_name: schedule_name }
    end

    private

    def schedule
      @schedule ||= pagerduty.get_schedules(query: schedule_name).first
    end

    def schedule_name
      @schedule_name ||= message.match_data[1].strip
    end

    def success_params
      {
        name: user[:summary],
        email: user[:email],
        layer_name: base_layer['layer_name'],
        schedule_name: schedule[:name]
      }
    end

    def base_layer
      @base_layer ||= pagerduty.get_base_layer schedule[:id],schedule[:time_zone]
    end

    def user
      @user ||= pagerduty.get_user base_layer['user'][:id]
    end
  end
end
