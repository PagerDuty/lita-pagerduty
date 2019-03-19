require 'spec_helper'

describe Pagerduty do
  let(:http) { double }
  let(:pagerduty) { Pagerduty.new(http, 'token', 'email') }

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
      OpenStruct.new(body: { incidents: [{id: 1}]}.to_json)
    )
    expect(pagerduty.get_incidents).to eq([{ id: 1 }])

    expect(http).to receive(:get).with('/incidents', {}).and_return(
      OpenStruct.new(body: { incidents: []}.to_json)
    )
    expect{ pagerduty.get_incidents }.to raise_exception Exceptions::IncidentsEmptyList
  end

  it 'get_incident' do
    expect(http).to receive(:get).with('/incidents/ABC123').and_return(
      OpenStruct.new(body: { incident: {}}.to_json)
    )
    pagerduty.get_incident('ABC123')
  end

  it 'get_users' do
    expect(http).to receive(:get).with('/users', {}).and_return(
      OpenStruct.new(body: { users: [{ id: 1 }]}.to_json)
    )
    expect(pagerduty.get_users).to eq [{ id: 1 }]

    expect(http).to receive(:get).with('/users', {}).and_return(
      OpenStruct.new(body: { users: []}.to_json)
    )
    expect{ pagerduty.get_users }.to raise_exception Exceptions::UsersEmptyList
  end

  it 'get_notes_by_incident_id' do
    expect(http).to receive(:get).with('/incidents/ABC123/notes').and_return(
      OpenStruct.new(body: { notes: [{ id: 1 }]}.to_json)
    )
    expect(pagerduty.get_notes_by_incident_id('ABC123')).to eq [{ id: 1 }]

    expect(http).to receive(:get).with('/incidents/ABC123/notes').and_return(
      OpenStruct.new(body: { notes: []}.to_json)
    )
    expect{ pagerduty.get_notes_by_incident_id('ABC123') }.to raise_exception Exceptions::NotesEmptyList
  end

  it 'manage_incidents' do
    params = { incidents: [
      { id: 'a', status: 'acknowledged', type: 'incident_reference' },
      { id: 'b', status: 'acknowledged', type: 'incident_reference' }
    ]}
    expect(http).to receive(:put).with('/incidents', params).and_return(
      OpenStruct.new(body: { users: [] }.to_json, status: 200)
    )
    pagerduty.manage_incidents(:acknowledge, ['a', 'b'])
  end

  it 'get_schedules' do
    expect(http).to receive(:get).with('/schedules', {}).and_return(
      OpenStruct.new(body: { schedules: [{ id: 1 }]}.to_json)
    )
    expect(pagerduty.get_schedules).to eq [{ id: 1 }]

    expect(http).to receive(:get).with('/schedules', {}).and_return(
      OpenStruct.new(body: { incidents: []}.to_json)
    )
    expect{ pagerduty.get_schedules }.to raise_exception Exceptions::SchedulesEmptyList
  end

  it 'get_oncall_user' do
    expect(http).to receive(:get).with('/oncalls', {}).and_return(
      OpenStruct.new(body: { oncalls: [{ id: 1, user: 'abc' }]}.to_json)
    )
    expect(pagerduty.get_oncall_user).to eq('abc')

    expect(http).to receive(:get).with('/oncalls', {}).and_return(
      OpenStruct.new(body: { incidents: []}.to_json)
    )
    expect{ pagerduty.get_oncall_user }.to raise_exception Exceptions::NoOncallUser
  end

  it 'override' do
    expect(Time).to receive(:now).and_return(Time.new(2000, 1, 1, 0, 0, 0, 0))
    params = { override: {
        end: '2000-01-01T00:01:10Z',
        start: '2000-01-01T00:00:10Z',
        user: { id: 'b', type: 'user_reference' }
    } }
    expect(http).to receive(:post).with('/schedules/a/overrides', params).and_return(
      OpenStruct.new(body: { override: []}.to_json, status: 201)
    )
    pagerduty.override('a', 'b', 1)
  end
end
