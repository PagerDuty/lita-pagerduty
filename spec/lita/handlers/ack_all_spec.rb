require 'spec_helper'

describe Lita::Handlers::Pagerduty, lita_handler: true do
  context 'ack all' do
    it do
      is_expected.to route_command('pager ack all').to(:ack_all)
    end

    it 'empty list' do
      expect_any_instance_of(Pagerduty).to receive(:get_incidents).and_raise(Exceptions::IncidentsEmptyList)
      send_command('pager ack all')
      expect(replies.last).to eq('No triggered, open, or acknowledged incidents')
    end

    it 'list of incidents' do
      expect_any_instance_of(Pagerduty).to receive(:get_incidents).and_return([
        { id: 'ABC123' }, { id: 'ABC124' }
      ])
      expect_any_instance_of(Pagerduty).to receive(:manage_incidents).and_return(
        OpenStruct.new(status: 200)
      )
      send_command('pager ack all')
      expect(replies.last).to eq('Acknowledged: ABC123, ABC124')
    end
  end
end
