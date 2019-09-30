# frozen_string_literal: true

require 'pdtime'

class Pagerduty # rubocop:disable Metrics/ClassLength
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

    data.first[:user]
  end

  def get_user(id)
    raise(ArgumentError, 'Id not provided') unless id

    response = http.get("/users/#{id}")
    raise Exceptions::NoUser if response.status == 404

    parse_json_response(response, :user)
  end

  def get_layer(id, range_begin, range_end)
    # Get the schedule with extra stuff resolved because we've passed through
    # the current time.
    url = "/schedules/#{id}?since=#{range_begin}&until=#{range_end}"
    response = http.get(url)
    raise Exceptions::ScheduleNotFound if response.status == 404

    last_layer = parse_json_response(response, :schedule)[:schedule_layers].last

    if last_layer[:rendered_schedule_entries].empty?
      raise Exceptions::PeriodNotProvided
    end

    last_layer
  end

  def get_base_layer(id, timezone)
    time_range = PDTime.get_time_range(timezone)

    layer = get_layer(id, time_range['now_begin'], time_range['now_end'])

    layer_entry = layer[:rendered_schedule_entries].first
    user = layer_entry[:user]

    {
      'layer_name' => layer[:name],
      'user' => user,
      'end' => layer_entry[:end],
      'now' => time_range['now_begin']
    }
  end

  def get_incident(id)
    raise(ArgumentError, 'Id not provided') unless id

    response = http.get("/incidents/#{id}")
    raise Exceptions::IncidentNotFound if response.status == 404

    parse_json_response(response, :incident)
  end

  def get_notes_by_incident_id(incident_id)
    response = http.get("/incidents/#{incident_id}/notes")
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
    response = http.put('/incidents', payload)
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
  # identified by +user_id+ on call for the period defined by +minutes+
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
