require 'spec_helper'

describe Lita::Handlers::Pagerduty, lita_handler: true do
  context 'resolve mine' do
    it do
      is_expected.to route_command('pager resolve mine').to(:resolve_mine)
    end

    it 'unknown user' do
      expect_any_instance_of(PagerDuty).to receive(:get_users).and_return([])
      user = Lita::User.create(123, name: 'foo')
      send_command('pager resolve mine', as: user)
      expect(replies.last).to eq('You have no triggered, open, or acknowledged incidents')
    end

    it 'empty list' do
      expect_any_instance_of(PagerDuty).to receive(:get_users).and_return([{ id: 'abc123' }])
      expect_any_instance_of(PagerDuty).to receive(:get_incidents).and_return([])
      send_command('pager resolve mine')
      expect(replies.last).to eq('You have no triggered, open, or acknowledged incidents')
    end

    it 'list of incidents' do
      expect_any_instance_of(PagerDuty).to receive(:get_users).and_return([{ id: 'abc123' }])
      expect_any_instance_of(PagerDuty).to receive(:get_incidents).and_return([
        { id: 'ABC123' }, { id: 'ABC124' }
      ])
      expect_any_instance_of(PagerDuty).to receive(:resolve_incidents).and_return(
        OpenStruct.new(status: 200)
      )
      send_command('pager resolve mine')
      expect(replies.last).to eq('Resolved: ABC123, ABC124')
    end
  end
end
