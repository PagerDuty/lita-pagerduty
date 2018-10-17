require 'spec_helper'

describe Lita::Handlers::Pagerduty, lita_handler: true do
  context 'ack ABC123' do
    it do
      is_expected.to route_command('pager ack ABC123').to(:ack)
    end

    it 'not found' do
      expect_any_instance_of(PagerDuty).to receive(:acknowledge_incidents).and_return(
        OpenStruct.new(status: 400)
      )
      send_command('pager ack ABC123')
      expect(replies.last).to be_nil
    end

    it 'found' do
      expect_any_instance_of(PagerDuty).to receive(:acknowledge_incidents).and_return(
        OpenStruct.new(status: 200)
      )
      send_command('pager ack ABC123')
      expect(replies.last).to eq 'Acknowledged: ABC123'
    end
  end
end
