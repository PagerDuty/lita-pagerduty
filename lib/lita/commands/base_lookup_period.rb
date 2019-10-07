# frozen_string_literal: true

module Commands
  class BaseLookupPeriod
    include Base

    def call
      response message: 'base_lookup_period.response', params: success_params
    rescue Exceptions::SchedulesEmptyList
      response message: 'base_lookup_period.no_matching_schedule',
               params: { schedule_name: schedule_name }
    rescue Exceptions::NoOncallUser
      response message: 'base_lookup_period.no_one_on_call',
               params: { schedule_name: schedule_name }
    end

    private

    def schedule
      @schedule ||= pagerduty.get_schedules(query: schedule_name).first
    end

    def schedule_name
      @schedule_name ||= message.match_data[1].strip
    end

    def unit
      @unit ||= message.match_data[2].strip
    end

    def offset
      if message.match_data[3].nil?
        @offset ||= 0
      else
        @offset ||= message.match_data[3].strip.to_i
      end
    end

    def success_params
      {
        name: users[:summary],
        email: users[:email],
        layer_name: users['layer_name'],
        schedule_name: schedule[:name],
        layer_entries: users['layer_entries'].join("\n"),
        override_entries: users['override_entries'].join("\n")
      }
    end

    def users
      id = schedule[:id]
      time_zone = schedule[:time_zone]

      if unit == 'month'
        time_range = PDTime.get_whole_month(time_zone, offset)
      elsif unit == 'year'
        time_range = PDTime.get_whole_year(time_zone, offset)
      else
        # TODO This doesn't work.
#         rescue Exceptions::UnknownUnit
#           response message: 'base_lookup_period.unknown_unit',
#                   params: {unit: unit}
        # It gives
#         SyntaxError: /home/ksandom/files/work/elastic/tasks/litabot/lita-pagerduty2/lib/lita/commands/base_lookup_period.rb:59: syntax error, unexpected keyword_rescue
#                 rescue Exceptions::UnknownUnit
#                 ^~~~~~

      end

      @users ||= pagerduty.get_users_from_layers(id, time_range)
    end
  end
end
