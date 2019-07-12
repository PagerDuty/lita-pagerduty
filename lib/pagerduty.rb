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

#   def get_user(params = {})
#     data = get_resources(:users, params)
#     raise Exceptions::NoOncallUser if data.empty?
# 
#     pp(data)
#     data.first
#   end

  def get_user(id = '404stub')
    response = http.get "/users/#{id}"
    raise Exceptions::NoOncallUser if response.status == 404 # TODO Update the exception being used here.
    data = parse_json_response(response, :user)
  end

  def get_base_layer(id = '404stub')
    # response = http.get "/schedules/#{id}?since=2019-06-28T06:00:00&until=2019-06-28T06:01:00" # Kevin
    response = http.get "/schedules/#{id}?since=2019-07-11T06:00:00&until=2019-07-11T06:01:00" # Oleksiy
    raise Exceptions::IncidentNotFound if response.status == 404 # TODO Update the exception being used here.
    data = parse_json_response(response, :schedule)
    #   * .schedule.schedule_layers[-1].rendered_schedule_entries[0].user - Weekly schedule. - This.
    last_layer = data[:schedule_layers].last
    layer_name = last_layer[:name]

    todothing = last_layer[:rendered_schedule_entries].first # TODO change the variable name.
    user = todothing[:user]
    user_id = user[:id]
    
    
    
    log.debug(layer_name)
    log.debug(user[:summary])
    
    output = Hash.new
    output['layer_name'] = layer_name
    output['user'] = user
    
    output


#     data = get_resources(:oncalls, params)
#     raise Exceptions::NoOncallUser if data.empty?
#
#     data.first.fetch(:user)
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
