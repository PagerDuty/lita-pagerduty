require 'spec_helper'

describe Pagerduty do
  let(:http) { double }
  let(:teams) { nil }
  let(:pagerduty) { Pagerduty.new(http, 'token', 'email', teams) }

  before do
    expect(http).to receive(:url_prefix=).with('https://api.pagerduty.com/')
    expect(http).to receive(:headers=).with({
      'Accept' => 'application/vnd.pagerduty+json;version=2',
      'Authorization' => 'Token token=token',
      'From' => 'email'
    })
  end

  def stub_response(response_hash)
    OpenStruct.new(body: response_hash.to_json)
  end

  def stub_collection_response(collection, params, response)
    uri = "/#{collection}"
    json = stub_response(collection => response)
    expect(http).to receive(:get).with(uri, params).and_return(json)
  end

  #-------------------------------------------------------------------------------------------------
  context "without teams filtering" do
    it 'get_incidents' do
      stub_collection_response(:incidents, {}, [{ id: 1 }])
      expect(pagerduty.get_incidents).to eq([{ id: 1 }])

      stub_collection_response(:incidents, {}, [])
      expect{ pagerduty.get_incidents }.to raise_exception Exceptions::IncidentsEmptyList
    end

    it 'get_users' do
      stub_collection_response(:users, {}, [{ id: 1 }])
      expect(pagerduty.get_users).to eq [{ id: 1 }]

      stub_collection_response(:users, {}, [])
      expect{ pagerduty.get_users }.to raise_exception Exceptions::UsersEmptyList
    end

    it 'get_schedules' do
      stub_collection_response(:schedules, {}, [{ id: 1 }])
      expect(pagerduty.get_schedules).to eq [{ id: 1 }]

      stub_collection_response(:schedules, {}, [])
      expect{ pagerduty.get_schedules }.to raise_exception Exceptions::SchedulesEmptyList
    end

    it 'get_oncall_user' do
      stub_collection_response(:oncalls, {}, [{ id: 1, user: 'abc' }])
      expect(pagerduty.get_oncall_user).to eq('abc')

      stub_collection_response(:oncalls, {}, [])
      expect{ pagerduty.get_oncall_user }.to raise_exception Exceptions::NoOncallUser
    end
  end

  #-------------------------------------------------------------------------------------------------
  context "with teams filtering enabled" do
    let(:teams) { [ 'team-a', 'team-b' ] }
    let(:teams_filter) { { team_ids: teams } }

    it 'get_incidents' do
      stub_collection_response(:incidents, teams_filter, [{ id: 1 }])
      expect(pagerduty.get_incidents).to eq([{ id: 1 }])

      stub_collection_response(:incidents, teams_filter, [])
      expect{ pagerduty.get_incidents }.to raise_exception Exceptions::IncidentsEmptyList
    end

    it 'get_users' do
      stub_collection_response(:users, teams_filter, [{ id: 1 }])
      expect(pagerduty.get_users).to eq [{ id: 1 }]

      stub_collection_response(:users, teams_filter, [])
      expect{ pagerduty.get_users }.to raise_exception Exceptions::UsersEmptyList
    end

    it 'get_schedules' do
      stub_collection_response(:schedules, teams_filter, [{ id: 1 }])
      expect(pagerduty.get_schedules).to eq [{ id: 1 }]

      stub_collection_response(:schedules, teams_filter, [])
      expect{ pagerduty.get_schedules }.to raise_exception Exceptions::SchedulesEmptyList
    end

    it 'get_oncall_user' do
      stub_collection_response(:oncalls, teams_filter, [{ id: 1, user: 'abc' }])
      expect(pagerduty.get_oncall_user).to eq('abc')

      stub_collection_response(:oncalls, teams_filter, [])
      expect{ pagerduty.get_oncall_user }.to raise_exception Exceptions::NoOncallUser
    end
  end

  #-------------------------------------------------------------------------------------------------
  # Methods that do not change their semantics with teams filtering enabled
  #-------------------------------------------------------------------------------------------------
  it 'get_incident' do
    expect(http).to receive(:get).with('/incidents/ABC123').and_return(
      stub_response(incident: {})
    )
    pagerduty.get_incident('ABC123')
  end

  it 'get_notes_by_incident_id' do
    expect(http).to receive(:get).with('/incidents/ABC123/notes').and_return(
      stub_response(notes: [{ id: 1 }])
    )
    expect(pagerduty.get_notes_by_incident_id('ABC123')).to eq [{ id: 1 }]

    expect(http).to receive(:get).with('/incidents/ABC123/notes').and_return(
      stub_response(notes: [])
    )
    expect{ pagerduty.get_notes_by_incident_id('ABC123') }.to raise_exception Exceptions::NotesEmptyList
  end

  it 'manage_incidents' do
    params = {
      incidents: [
        { id: 'a', status: 'acknowledged', type: 'incident_reference' },
        { id: 'b', status: 'acknowledged', type: 'incident_reference' },
      ]
    }
    expect(http).to receive(:put).with('/incidents', params).and_return(
      OpenStruct.new(body: { users: [] }.to_json, status: 200)
    )
    pagerduty.manage_incidents(:acknowledge, ['a', 'b'])
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
