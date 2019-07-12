
bundle install;ADAPTER=shell bundle exec lita
pager base swiftype-sre-hybrid


* To get the on-call person for a given layer,
  * Both since and until must be specified.
  * it must be a URL variable. Eg ?since=2019-07-11T12:00:00&until=2019-07-11T12:01:00
* Interesting json paths
  * .schedule.final_schedule.rendered_schedule_entries[0].user - Final schedule. - Covered by `oncall`
  * .schedule.schedule_layers[-1].rendered_schedule_entries[0].user - Weekly schedule. - This.
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

```bash
export HOUR=06; testPD "/schedules/P4ZPGKF?since=2019-07-11T$HOUR:00:00&until=2019-07-11T$HOUR:01:00"
export HOUR=11; testPD "/schedules/P4ZPGKF?since=2019-07-11T$HOUR:00:00&until=2019-07-11T$HOUR:01:00"
export HOUR=12; testPD "/schedules/P4ZPGKF?since=2019-07-11T$HOUR:00:00&until=2019-07-11T$HOUR:01:00"
export HOUR=06; testPD "/schedules/P4ZPGKF?since=2019-07-11T$HOUR:00:00&until=2019-07-11T$HOUR:01:00" | jq '.schedule.schedule_layers[-1].rendered_schedule_entries[0].user' - Returns Oleksiy.
export HOUR=06; testPD "/schedules/P4ZPGKF?since=2019-07-02T$HOUR:00:00&until=2019-07-02T$HOUR:01:00" | jq '.schedule.schedule_layers[-1].rendered_schedule_entries[0].user' - Returns Andrew.
export HOUR=06; testPD "/schedules/P4ZPGKF?since=2019-06-28T$HOUR:00:00&until=2019-06-28T$HOUR:01:00" | jq '.schedule.schedule_layers[-1].rendered_schedule_entries[0].user' - Returns Kevin.
export HOUR=06; testPD "/schedules/P4ZPGKF?since=2019-06-22T$HOUR:00:00&until=2019-06-22T$HOUR:01:00" | jq '.schedule.schedule_layers[-1].rendered_schedule_entries[0].user' - Returns Brian.
```
