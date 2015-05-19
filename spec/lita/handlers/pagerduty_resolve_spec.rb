require 'spec_helper'

describe Lita::Handlers::PagerdutyResolve, lita_handler: true do
  include_context 'basic fixtures'

  it do
    is_expected.to route_command('pager resolve all').to(:resolve_all)
    is_expected.to route_command('pager resolve mine').to(:resolve_mine)
    is_expected.to route_command('pager resolve ABC123').to(:resolve)
  end

  describe '#resolve_all' do
    describe 'when there are resolvable incidents' do
      it 'shows them as resolved' do
        expect(Pagerduty).to receive(:new).twice { incidents }
        send_command('pager resolve all')
        expect(replies.last).to eq('Resolved: ABC789')
      end
    end

    describe 'when there are no resolvable incidents' do
      it 'shows a warning' do
        expect(Pagerduty).to receive(:new) { no_incidents }
        send_command('pager resolve all')
        expect(replies.last).to eq('No triggered, open, or acknowledged ' \
                                   'incidents')
      end
    end
  end

  describe '#resolve_mine' do
    describe 'when there are resolvable incidents for the user' do
      it 'shows them as acknowledged' do
        bar = Lita::User.create(123, name: 'bar')
        expect(Pagerduty).to receive(:new).twice { incidents }
        send_command('pager identify bar@example.com', as: bar)
        send_command('pager resolve mine', as: bar)
        expect(replies.last).to eq('Resolved: ABC789')
      end
    end

    describe 'when there are no resolvable incidents for the user' do
      it 'shows a warning' do
        foo = Lita::User.create(123, name: 'foo')
        expect(Pagerduty).to receive(:new) { incidents }
        send_command('pager identify foo@example.com', as: foo)
        send_command('pager resolve mine', as: foo)
        expect(replies.last).to eq('You have no triggered, open, or ' \
                                   'acknowledged incidents')
      end
    end

    describe 'when the user has not identified themselves' do
      it 'shows a warning' do
        send_command('pager resolve mine')
        expect(replies.last).to eq('You have not identified yourself (use ' \
                                   'the help command for more info)')
      end
    end
  end

  describe '#resolve' do
    describe 'when the incident has not been resolved' do
      it 'shows the resolve' do
        expect(Pagerduty).to receive(:new) { new_incident }
        send_command('pager resolve ABC123')
        expect(replies.last).to eq('ABC123: Incident resolved')
      end
    end

    describe 'when the incident has already been resolved' do
      it 'shows the warning' do
        expect(Pagerduty).to receive(:new) { resolved_incident }
        send_command('pager resolve ABC123')
        expect(replies.last).to eq('ABC123: Incident already resolved')
      end
    end

    describe 'when the incident does not exist' do
      it 'shows an error' do
        expect(Pagerduty).to receive(:new) { no_incident }
        send_command('pager resolve ABC123')
        expect(replies.last).to eq('ABC123: Incident not found')
      end
    end
  end
end
