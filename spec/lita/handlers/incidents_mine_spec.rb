require 'spec_helper'

describe Lita::Handlers::Pagerduty, lita_handler: true do
  context 'incidents mine' do
    it do
      is_expected.to route_command('pager incidents mine').to(:incidents_mine)
    end

    it 'unknown user' do
      expect_any_instance_of(PagerDuty).to receive(:get_users).and_return([])
      user = Lita::User.create(123, name: 'foo')
      send_command('pager incidents mine', as: user)
      expect(replies.last).to eq('You have no triggered, open, or acknowledged incidents')
    end

    it 'empty list' do
      user = Lita::User.create(123, name: 'foo')
      send_command('pager identify foo@pagerduty.com', as: user)
      expect_any_instance_of(PagerDuty).to receive(:get_users).and_return([{ id: 'abc123'}])
      expect_any_instance_of(PagerDuty).to receive(:get_incidents).and_return([])
      send_command('pager incidents mine', as: user)
      expect(replies.last).to eq('No triggered, open, or acknowledged incidents')
    end

    it 'list of incidents' do
      user = Lita::User.create(123, name: 'foo')
      send_command('pager identify foo@pagerduty.com', as: user)
      expect_any_instance_of(PagerDuty).to receive(:get_users).and_return([{ id: 'abc123'}])
      expect_any_instance_of(PagerDuty).to receive(:get_incidents).and_return([
        { id: 'ABC123', title: 'ABC', html_url: 'https://foo.pagerduty.com/incidents/ABC123', assignments: [{ assignee: { summary: 'foo' } }] }
      ])
      send_command('pager incidents mine', as: user)
      expect(replies.last).to eq('ABC123: "ABC", assigned to: "foo", url: https://foo.pagerduty.com/incidents/ABC123')
    end
  end
end
