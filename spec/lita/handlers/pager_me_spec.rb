require 'spec_helper'

describe Lita::Handlers::Pagerduty, lita_handler: true do
  context 'pager me abc 1m' do
    it do
      is_expected.to route_command('pager me abc 1m').to(:pager_me)
    end

    it 'unknown user' do
      user = Lita::User.create(123, name: 'foo')
      send_command('pager me abc 1m', as: user)
      expect(replies.last).to eq('You have not identified yourself (use the help command for more info)')
    end

    it 'unrecognised user' do
      user = Lita::User.create(123, name: 'foo')
      send_command('pager identify foo@pagerduty.com', as: user)
      expect_any_instance_of(PagerDuty).to receive(:get_schedules).and_return([{ id: 'bcd123'}])
      expect_any_instance_of(PagerDuty).to receive(:get_users).and_return([])
      send_command('pager me abc 1m', as: user)
      expect(replies.last).to eq('You have identified yourself with an email address unknown to PagerDuty')
    end

    it 'unknown schedule' do
      user = Lita::User.create(123, name: 'foo')
      send_command('pager identify foo@pagerduty.com', as: user)
      expect_any_instance_of(PagerDuty).to receive(:get_schedules).and_return([])
      send_command('pager me abc 1m', as: user)
      expect(replies.last).to eq('No matching schedules found for \'abc\'')
    end

    it 'failure' do
      user = Lita::User.create(123, name: 'foo')
      send_command('pager identify foo@pagerduty.com', as: user)
      expect_any_instance_of(PagerDuty).to receive(:get_schedules).and_return([{ id: 'abc123' }])
      expect_any_instance_of(PagerDuty).to receive(:get_users).and_return([{id: 'abc123'}])
      expect_any_instance_of(PagerDuty).to receive(:override).and_return(nil)
      send_command('pager me abc 1m', as: user)
      expect(replies.last).to eq('failed to take the pager')
    end

    it 'success' do
      user = Lita::User.create(123, name: 'foo')
      send_command('pager identify foo@pagerduty.com', as: user)
      expect_any_instance_of(PagerDuty).to receive(:get_schedules).and_return([{ id: 'abc123' }])
      expect_any_instance_of(PagerDuty).to receive(:get_users).and_return([{id: 'abc123', email: 'foo@pagerduty.com'}])
      expect_any_instance_of(PagerDuty).to receive(:override).and_return({
        user: { summary: 'foo' },
        end: 12345
      })
      send_command('pager me abc 1m', as: user)
      expect(replies.last).to eq('foo (foo@pagerduty.com) is now on call until 12345')
    end
  end
end
