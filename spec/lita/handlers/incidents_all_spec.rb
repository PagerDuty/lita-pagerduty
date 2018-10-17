require 'spec_helper'

describe Lita::Handlers::Pagerduty, lita_handler: true do
  context 'incidents all' do
    it do
      is_expected.to route_command('pager incidents all').to(:incidents_all)
    end

    it 'empty list' do
      expect_any_instance_of(PagerDuty).to receive(:get_incidents).and_return([])
      send_command('pager incidents all')
      expect(replies.last).to eq('No triggered, open, or acknowledged incidents')
    end

    it 'list of incidents' do
      expect_any_instance_of(PagerDuty).to receive(:get_incidents).and_return([
        { id: 'ABC123', title: 'ABC', html_url: 'https://foo.pagerduty.com/incidents/ABC123' }
      ])
      send_command('pager incidents all')
      expect(replies.last).to eq('ABC123: "ABC", assigned to: "none", url: https://foo.pagerduty.com/incidents/ABC123')
    end

    it 'list of assigned incidents' do
      expect_any_instance_of(PagerDuty).to receive(:get_incidents).and_return([
        { id: 'ABC123', title: 'ABC', html_url: 'https://foo.pagerduty.com/incidents/ABC123', assignments: [{ assignee: { summary: 'foo' } }] }
      ])
      send_command('pager incidents all')
      expect(replies.last).to eq('ABC123: "ABC", assigned to: "foo", url: https://foo.pagerduty.com/incidents/ABC123')
    end
  end
end
