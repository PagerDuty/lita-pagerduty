require 'spec_helper'

describe Lita::Handlers::Pagerduty, lita_handler: true do
  context 'base abc' do
    it do
      is_expected.to route_command('pager base abc').to(:base_lookup)
    end

    it 'schedule not found' do
      expect_any_instance_of(Pagerduty).to receive(:get_schedules).and_raise(Exceptions::SchedulesEmptyList)
      send_command('pager base abc')
      expect(replies.last).to eq('No matching schedules found for \'abc\'')
    end

    it 'no one on call' do
      expect_any_instance_of(Pagerduty).to receive(:get_schedules).and_return([{ id: 'abc123', name: 'abc', time_zone: 'America/Los_Angeles' }])
      expect_any_instance_of(Pagerduty).to receive(:get_base_layer).and_return({ 'now' => '2019-07-31T08:56:00', 'end' => '2019-07-31T08:56:01-07:00', 'layer_name' => 'Thingery', 'user' => { id: 'abc123' } })
      expect_any_instance_of(Pagerduty).to receive(:get_user).and_raise(Exceptions::NoOncallUser)
      send_command('pager base abc')
      expect(replies.last).to eq('No one is currently on call for abc')
    end

    it 'somebody on call' do
      expect_any_instance_of(Pagerduty).to receive(:get_schedules).and_return([{ id: 'abc123', name: 'abc', time_zone: 'America/Los_Angeles' }])
      expect_any_instance_of(Pagerduty).to receive(:get_base_layer).and_return({ 'now' => '2019-07-31T08:56:00', 'end' => '2019-07-31T08:56:01-07:00', 'layer_name' => 'Thingery', 'user' => { id: 'abc123' } })
      expect_any_instance_of(Pagerduty).to receive(:get_user).and_return({summary: 'foo', email: 'foo@pagerduty.com'})
      send_command('pager base abc')
      expect(replies.last).to eq('foo (foo@pagerduty.com) is on call in the base layer (Thingery) of abc.')
    end
  end
end
