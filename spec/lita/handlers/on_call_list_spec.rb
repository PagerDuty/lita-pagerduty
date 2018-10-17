require 'spec_helper'

describe Lita::Handlers::Pagerduty, lita_handler: true do
  context 'oncall' do
    it do
      is_expected.to route_command('pager oncall').to(:on_call_list)
    end

    it 'empty list' do
      expect_any_instance_of(PagerDuty).to receive(:get_schedules).and_return([])
      send_command('pager oncall')
      expect(replies.last).to eq('No schedules found')
    end

    it 'list' do
      expect_any_instance_of(PagerDuty).to receive(:get_schedules).and_return([
        { name: 'A' }, { name: 'B' }
      ])
      send_command('pager oncall')
      expect(replies.last).to eq("Available schedules:\nA\nB")
    end
  end
end
