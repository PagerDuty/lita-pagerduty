require 'spec_helper'

describe Lita::Handlers::Pagerduty, lita_handler: true do
  context 'incident ABC123' do
    it do
      is_expected.to route_command('pager incident ABC123').to(:incident)
    end

    it 'found' do
      expect_any_instance_of(Pagerduty).to receive(:get_incident).and_return({
        id: 'ABC123', title: 'ABC', html_url: 'https://foo.pagerduty.com/incidents/ABC123'
      })
      send_command('pager incident ABC123')
      expect(replies.last).to eq('ABC123: "ABC", assigned to: "none", url: https://foo.pagerduty.com/incidents/ABC123')
    end

    it 'not found' do
      expect_any_instance_of(Pagerduty).to receive(:get_incident).and_raise(Exceptions::IncidentNotFound)
      send_command('pager incident ABC123')
      expect(replies.last).to eq('ABC123: Incident not found')
    end
  end
end
