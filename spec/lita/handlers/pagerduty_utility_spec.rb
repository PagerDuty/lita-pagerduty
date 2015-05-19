require 'spec_helper'

describe Lita::Handlers::PagerdutyUtility, lita_handler: true do
  include_context 'basic fixtures'

  it do
    is_expected.to route_command('pager oncall').to(:on_call_list)
    is_expected.to route_command('pager oncall ops').to(:on_call_lookup)
    is_expected.to route_command('pager identify foobar@example.com').to(:identify)
    is_expected.to route_command('pager forget').to(:forget)
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
end
