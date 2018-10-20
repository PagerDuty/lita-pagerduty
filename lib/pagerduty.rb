class Pagerduty
  def initialize(http, token, email)
    @token = token
    @http = http
    http.url_prefix = 'https://api.pagerduty.com/'
    http.headers = headers(email)
  end

  def get_incidents(params = {})
    response = @http.get '/incidents', params
    data = JSON.parse(response.body, symbolize_names: true)
               .fetch(:incidents, [])
    raise Exceptions::IncidentsEmptyList if data.empty?
    data
  end

  def get_users(params = {})
    response = @http.get '/users', params
    data = JSON.parse(response.body, symbolize_names: true).fetch(:users, [])
    raise Exceptions::UsersEmptyList if data.empty?
    data
  end

  def get_schedules(params = {})
    response = @http.get '/schedules', params
    data = JSON.parse(response.body, symbolize_names: true)
               .fetch(:schedules, [])
    raise Exceptions::SchedulesEmptyList if data.empty?
    data
  end

  def get_oncall_user(params = {})
    response = @http.get '/oncalls', params
    data = JSON.parse(response.body, symbolize_names: true).fetch(:oncalls, [])
    raise Exceptions::NoOncallUser if data.empty?
    data.first.fetch(:user)
  end

  def get_incident(id = '404stub')
    response = @http.get "/incidents/#{id}"
    raise Exceptions::IncidentNotFound if response.status == 404
    JSON.parse(response.body, symbolize_names: true).fetch(:incident, nil)
  end

  def get_notes_by_incident_id(incident_id)
    response = @http.get "/incidents/#{incident_id}/notes"
    raise Exceptions::IncidentNotFound if response.status == 404
    data = JSON.parse(response.body, symbolize_names: true).fetch(:notes, [])
    raise Exceptions::NotesEmptyList if data.empty?
    data
  end

  def manage_incidents(action, ids)
    incidents = ids.map do |id|
      { id: id, type: 'incident_reference', status: "#{action}d" }
    end
    payload = { incidents: incidents }
    response = @http.put '/incidents', payload
    raise Exceptions::IncidentManageUnsuccess if response.status != 200
    response
  end

  def override(schedule_id, user_id, minutes)
    from = ::Time.now.utc + 10
    to = from + (60 * minutes)
    payload = { override: {
      start: from.iso8601,
      end: to.iso8601,
      user: { id: user_id, type: 'user_reference' }
    } }
    response = @http.post "/schedules/#{schedule_id}/overrides", payload
    raise Exceptions::OverrideUnsuccess if response.status != 201
    JSON.parse(response.body, symbolize_names: true).fetch(:override, nil)
  end

  private

  def headers(email)
    {
      'Accept' => 'application/vnd.pagerduty+json;version=2',
      'Authorization' => "Token token=#{@token}",
      'From' => email
    }
  end
end
