require 'tzinfo'

class Pagerduty
  attr_reader :http, :teams

  def initialize(http, token, email, teams = [])
    @http = http
    @teams = teams || []

    http.url_prefix = 'https://api.pagerduty.com/'
    http.headers = auth_headers(email, token)
  end

  def log
    Lita.logger
  end

#   def tzinfo
#     TZInfo
#   end

  def get_incidents(params = {})
    data = get_resources(:incidents, params)
    raise Exceptions::IncidentsEmptyList if data.empty?

    data
  end

  def get_users(params = {})
    data = get_resources(:users, params)
    raise Exceptions::UsersEmptyList if data.empty?

    data
  end

  def get_schedules(params = {})
    data = get_resources(:schedules, params)
    raise Exceptions::SchedulesEmptyList if data.empty?

    data
  end

  def get_oncall_user(params = {})
    data = get_resources(:oncalls, params)
    raise Exceptions::NoOncallUser if data.empty?

    data[:user]
  end

# TODO Remove this unless we can find the cause of the problem.
# This is my original code. It would be great if we could get it to work, because it would fit with the surrounding code, but it just wasn't picking up the ID, so it was simply returning everything.
# I beleive it needs to be called with something like from base_lookup.rb:
#     def oncall_user_params
#       { 'user_ids[]' => base_layer['users'][:id], 'include[]' => 'user' }
#     end
# and
#     @user ||= pagerduty.get_user oncall_user_params

# Original code ---v
#   def get_user(params = {})
#     data = get_resources(:users, params)
#     raise Exceptions::NoOncallUser if data.empty?
# 
#     pp(data)
#     data.first
#   end

  def get_user(id = '404stub')
    response = http.get "/users/#{id}"
    raise Exceptions::NoUser if response.status == 404
    data = parse_json_response(response, :user)
  end

  def get_base_layer(id = '404stub', timezone)
    # Get now in the timezone of the schedule.

    log.debug(timezone)
    timezone_object = ::TZInfo::Timezone.get(timezone)
    utc_offset = timezone_object.current_period.utc_total_offset_rational.numerator

    #utc_offset = -7
    log.debug(utc_offset)
    local = DateTime.now
    now_begin = local.new_offset(Rational(utc_offset, 24)).strftime("%Y-%m-%dT%H:%M:00")
    now_end = local.new_offset(Rational(utc_offset, 24)).strftime("%Y-%m-%dT%H:%M:01")

    log.debug(now_begin)
    log.debug(now_end)

    # Get the schedule with extra stuff resolved because we've passed through the current time.
    response = http.get "/schedules/#{id}?since=2019-07-11T06:00:00&until=2019-07-11T06:01:00" # Oleksiy
    raise Exceptions::ScheduleNotFound if response.status == 404

    # Get out useful data.
    last_layer = parse_json_response(response, :schedule)[:schedule_layers].last
    layer_name = last_layer[:name]

    todothing = last_layer[:rendered_schedule_entries].first # TODO change the variable name.
    user = todothing[:user]
    user_id = user[:id]

    log.debug(layer_name)
    log.debug(user[:summary])

    # Get it ready to send back.
    output = Hash.new
    output['layer_name'] = layer_name
    output['user'] = user

    output
  end

  def get_incident(id = '404stub')
    response = http.get "/incidents/#{id}"
    raise Exceptions::IncidentNotFound if response.status == 404

    parse_json_response(response, :incident)
  end

  def get_notes_by_incident_id(incident_id)
    response = http.get "/incidents/#{incident_id}/notes"
    raise Exceptions::IncidentNotFound if response.status == 404

    data = parse_json_response(response, :notes, [])
    raise Exceptions::NotesEmptyList if data.empty?

    data
  end

  def manage_incidents(action, ids)
    incidents = ids.map do |id|
      { id: id, type: 'incident_reference', status: "#{action}d" }
    end
    payload = { incidents: incidents }
    response = http.put '/incidents', payload
    raise Exceptions::IncidentManageUnsuccess if response.status != 200

    response
  end

  def override(schedule_id, user_id, minutes)
    payload = override_payload(user_id, minutes)
    response = http.post("/schedules/#{schedule_id}/overrides", payload)
    raise Exceptions::OverrideUnsuccess if response.status != 201

    parse_json_response(response, :override)
  end

  private

  def auth_headers(email, token)
    {
      'Accept' => 'application/vnd.pagerduty+json;version=2',
      'Authorization' => "Token token=#{token}",
      'From' => email
    }
  end

  # Fetches a list of resources from a given collection using Pagerduty REST API
  def get_resources(collection_name, params = {})
    # Scope down to a single team
    params[:team_ids] = teams if teams.any?

    # Get the resources
    response = http.get("/#{collection_name}", params)

    # Parse the reponse and get the objects from the collection
    parse_json_response(response, collection_name, [])
  end

  # Parses a JSON response and fetches a specific key from it
  def parse_json_response(response, response_key, default_value = nil)
    data = JSON.parse(response.body, symbolize_names: true)
    data.fetch(response_key, default_value)
  end

  # Returns a payload for overriding a schedule and putting the user
  # identified by +user_id+ on-call for the period defined by +minutes+
  def override_payload(user_id, minutes)
    # start 10 sec from now
    from = ::Time.now.utc + 10
    to = from + (60 * minutes)

    {
      override: {
        start: from.iso8601, end: to.iso8601,
        user: { id: user_id, type: 'user_reference' }
      }
    }
  end
end
