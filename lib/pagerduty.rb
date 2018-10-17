class PagerDuty
  def initialize(http, token, email)
    @token = token
    @http = http
    http.url_prefix = 'https://api.pagerduty.com/'
    http.headers = headers(email)
  end

  def get_incidents(params = {})
    response = @http.get '/incidents', params
    JSON.parse(response.body, symbolize_names: true).fetch(:incidents, [])
  end

  def get_incident(id = '404stub')
    response = @http.get "/incidents/#{id}"
    JSON.parse(response.body, symbolize_names: true).fetch(:incident, nil)
  end

  def get_users(params = {})
    response = @http.get '/users', params
    JSON.parse(response.body, symbolize_names: true).fetch(:users, [])
  end

  def get_notes_by_incident_id(id)
    response = @http.get "/incidents/#{id}/notes"
    raise 'Incident not found' if response.status == 404

    JSON.parse(response.body, symbolize_names: true).fetch(:notes, [])
  end

  def acknowledge_incidents(ids)
    incidents = ids.map do |id|
      {
        id: id,
        type: 'incident_reference',
        status: 'acknowledged'
      }
    end
    payload = { incidents: incidents }
    @http.put '/incidents', payload
  end

  def resolve_incidents(ids)
    incidents = ids.map do |id|
      {
        id: id,
        type: 'incident_reference',
        status: 'resolved'
      }
    end
    payload = { incidents: incidents }
    @http.put '/incidents', payload
  end

  def get_schedules(params = {})
    response = @http.get '/schedules', params
    JSON.parse(response.body, symbolize_names: true).fetch(:schedules, [])
  end

  def get_oncalls(params = {})
    response = @http.get '/oncalls', params
    JSON.parse(response.body, symbolize_names: true).fetch(:oncalls, [])
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
