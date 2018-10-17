require 'spec_helper'

describe PagerDuty do
  let(:http) { double }
  let(:pagerduty) { PagerDuty.new(http, 'token', 'email') }

  before :each do
    expect(http).to receive(:url_prefix=).with('https://api.pagerduty.com/')
    expect(http).to receive(:headers=).with({
      'Accept' => 'application/vnd.pagerduty+json;version=2',
      'Authorization' => 'Token token=token',
      'From' => 'email'
    })
  end

  it 'get_incidents' do
    expect(http).to receive(:get).with('/incidents', {}).and_return(
      OpenStruct.new(body: { incidents: []}.to_json)
    )
    pagerduty.get_incidents
  end

  it 'get_incident' do
    expect(http).to receive(:get).with('/incidents/ABC123').and_return(
      OpenStruct.new(body: { incident: {}}.to_json)
    )
    pagerduty.get_incident('ABC123')
  end

  it 'get_users' do
    expect(http).to receive(:get).with('/users', {}).and_return(
      OpenStruct.new(body: { users: []}.to_json)
    )
    pagerduty.get_users
  end

  it 'get_notes_by_incident_id' do
    expect(http).to receive(:get).with('/incidents/ABC123/notes').and_return(
      OpenStruct.new(body: { users: []}.to_json)
    )
    pagerduty.get_notes_by_incident_id('ABC123')
  end

  it 'acknowledge_incidents' do
    params = { incidents: [
      { id: 'a', status: 'acknowledged', type: 'incident_reference' },
      { id: 'b', status: 'acknowledged', type: 'incident_reference' }
    ]}
    expect(http).to receive(:put).with('/incidents', params).and_return(
      OpenStruct.new(body: { users: []}.to_json)
    )
    pagerduty.acknowledge_incidents(['a', 'b'])
  end

  it 'resolve_incidents' do
    params = { incidents: [
      { id: 'a', status: 'resolved', type: 'incident_reference' },
      { id: 'b', status: 'resolved', type: 'incident_reference' }
    ]}
    expect(http).to receive(:put).with('/incidents', params).and_return(
      OpenStruct.new(body: { users: []}.to_json)
    )
    pagerduty.resolve_incidents(['a', 'b'])
  end

  it 'get_schedules' do
    expect(http).to receive(:get).with('/schedules', {}).and_return(
      OpenStruct.new(body: { schedules: []}.to_json)
    )
    pagerduty.get_schedules
  end

  it 'get_oncalls' do
    expect(http).to receive(:get).with('/oncalls', {}).and_return(
      OpenStruct.new(body: { oncalls: []}.to_json)
    )
    pagerduty.get_oncalls
  end

  it 'override' do
    expect(Time).to receive(:now).and_return(Time.new(2000))
    params = { override: {
        end: '2000-01-01T00:01:10Z',
        start: '2000-01-01T00:00:10Z',
        user: { id: 'b', type: 'user_reference' }
    } }
    expect(http).to receive(:post).with('/schedules/a/overrides', params).and_return(
      OpenStruct.new(body: { override: []}.to_json)
    )
    pagerduty.override('a', 'b', 1)
  end
end
