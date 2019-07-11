/*

* To get the on-call person for a given layer,
  * Both since and until must be specified.
  * it must be a URL variable. Eg ?since=2019-07-11T12:00:00&until=2019-07-11T12:01:00
* Interesting json paths
  * .schedule.final_schedule.rendered_schedule_entries[0].user - Final schedule.
  * .schedule.schedule_layers[-1].rendered_schedule_entries[0].user - Weekly schedule.
* Interesting times for testing
  * 06:00:00
    * final_schedule: Kevin
    * Weekly: Oleksiy
  * 12:00:00
    * final_schedule: Andrew
    * Weekly: Oleksiy
  * 11:00:00
    * final_schedule: Oleksiy
    * Weekly: Oleksiy
*/

# export HOUR=06; testPD "/schedules/P4ZPGKF?since=2019-07-11T$HOUR:00:00&until=2019-07-11T$HOUR:01:00"
# export HOUR=11; testPD "/schedules/P4ZPGKF?since=2019-07-11T$HOUR:00:00&until=2019-07-11T$HOUR:01:00"
# export HOUR=12; testPD "/schedules/P4ZPGKF?since=2019-07-11T$HOUR:00:00&until=2019-07-11T$HOUR:01:00"
# export HOUR=06; testPD "/schedules/P4ZPGKF?since=2019-07-11T$HOUR:00:00&until=2019-07-11T$HOUR:01:00" | jq '.schedule.schedule_layers[-1].rendered_schedule_entries[0].user' - Returns Oleksiy.
# export HOUR=06; testPD "/schedules/P4ZPGKF?since=2019-07-02T$HOUR:00:00&until=2019-07-02T$HOUR:01:00" | jq '.schedule.schedule_layers[-1].rendered_schedule_entries[0].user' - Returns Andrew.
# export HOUR=06; testPD "/schedules/P4ZPGKF?since=2019-06-28T$HOUR:00:00&until=2019-06-28T$HOUR:01:00" | jq '.schedule.schedule_layers[-1].rendered_schedule_entries[0].user' - Returns Kevin.
# export HOUR=06; testPD "/schedules/P4ZPGKF?since=2019-06-22T$HOUR:00:00&until=2019-06-22T$HOUR:01:00" | jq '.schedule.schedule_layers[-1].rendered_schedule_entries[0].user' - Returns Brian.


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
      @user ||= pagerduty.get_base_oncall_user oncall_user_params
    end
  end
end
