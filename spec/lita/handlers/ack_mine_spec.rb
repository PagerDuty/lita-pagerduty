require 'spec_helper'

describe Lita::Handlers::Pagerduty, lita_handler: true do
  context 'ack mine' do
    it do
      is_expected.to route_command('pager ack mine').to(:ack_mine)
    end

    it 'unknown user' do
      user = Lita::User.create(123, name: 'foo')
      send_command('pager ack mine', as: user)
      expect(replies.last).to eq('You have no triggered, open, or acknowledged incidents')
    end

    it 'empty list' do
      user = Lita::User.create(123, name: 'foo')
      send_command('pager identify foo@pagerduty.com', as: user)
      expect_any_instance_of(Pagerduty).to receive(:get_users).and_return([{ id: 'abc123' }])
      expect_any_instance_of(Pagerduty).to receive(:get_incidents).and_raise(Exceptions::IncidentsEmptyList)
      send_command('pager ack mine', as: user)
      expect(replies.last).to eq('You have no triggered, open, or acknowledged incidents')
    end

    it 'list of incidents' do
      user = Lita::User.create(123, name: 'foo')
      send_command('pager identify foo@pagerduty.com', as: user)
      expect_any_instance_of(Pagerduty).to receive(:get_users).and_return([{ id: 'abc123' }])
      expect_any_instance_of(Pagerduty).to receive(:get_incidents).and_return([
        { id: 'ABC123' }, { id: 'ABC124' }
      ])
      expect_any_instance_of(Pagerduty).to receive(:manage_incidents).and_return(
        OpenStruct.new(status: 200)
      )
      send_command('pager ack mine', as: user)
      expect(replies.last).to eq('Acknowledged: ABC123, ABC124')
    end
  end
end
