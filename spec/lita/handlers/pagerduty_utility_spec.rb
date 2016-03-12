require 'spec_helper'

describe Lita::Handlers::PagerdutyUtility, lita_handler: true do
  include_context 'basic fixtures'

  it do
    is_expected.to route_command('pager oncall').to(:on_call_list)
    is_expected.to route_command('pager oncall ops').to(:on_call_lookup)
    is_expected.to route_command('pager identify foobar@example.com').to(:identify)
    is_expected.to route_command('pager forget').to(:forget)
    is_expected.to route_command('pager whoami').to(:whoami)
    is_expected.to route_command('pager me ops 12m').to(:pager_me)
  end

  before do
    Lita.config.handlers.pagerduty.api_key = 'foo'
    Lita.config.handlers.pagerduty.subdomain = 'bar'
  end

  describe '#identify' do
    describe 'when that email is new' do
      it 'shows a successful identification' do
        foo = Lita::User.create(123, name: 'foo')
        send_command('pager identify foo@example.com', as: foo)
        expect(replies.last).to eq('You have now been identified.')
      end
    end

    # TODO: It'd be great to validate this against the existing
    # users on the PD account.

    describe 'when that email exists already' do
      it 'shows a warning' do
        baz = Lita::User.create(321, name: 'baz')
        send_command('pager identify baz@example.com', as: baz)
        send_command('pager identify baz@example.com', as: baz)
        expect(replies.last).to eq('You have already been identified!')
      end
    end
  end

  describe '#forget' do
    describe 'when that user is associated' do
      it 'shows a successful forget' do
        foo = Lita::User.create(123, name: 'foo')
        send_command('pager identify foo@example.com', as: foo)
        send_command('pager forget', as: foo)
        expect(replies.last).to eq('Your email has now been forgotten.')
      end
    end

    describe 'when that user is not associated' do
      it 'shows a warning' do
        foo = Lita::User.create(123, name: 'foo')
        send_command('pager forget', as: foo)
        expect(replies.last).to eq('No email on record for you.')
      end
    end
  end

  describe '#whoami' do
    it 'shows the user when associated' do
      foo = Lita::User.create(123, name: 'foo')
      send_command('pager identify foo@example.com', as: foo)
      send_command('pager whoami', as: foo)
      expect(replies.last).to eq('You have been identified as foo@example.com')
    end

    it 'shows the user automatically if they have an email attribute' do
      foo = Lita::User.create(123, name: 'foo', email: 'foo@example.com')
      send_command('pager whoami', as: foo)
      expect(replies.last).to eq('You have been identified as foo@example.com')
    end

    it 'shows a warning when that user is not associated' do
      send_command('pager whoami')
      expect(replies.last).to eq('You have not been identified')
    end
  end
end
