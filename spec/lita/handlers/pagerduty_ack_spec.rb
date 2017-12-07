require 'spec_helper'

describe Lita::Handlers::PagerdutyAck, lita_handler: true do
  include_context 'basic fixtures'

  it do
    is_expected.to route_command('pager ack all').to(:ack_all)
    is_expected.to route_command('pager ack mine').to(:ack_mine)
    is_expected.to route_command('pager ack ABC123').to(:ack)
  end

  describe '#ack_all' do
    describe 'when there are acknowledgable incidents' do
      it 'shows them as acknowledged' do
        expect(Pagerduty).to(receive(:new).twice { incidents })
        send_command('pager ack all')
        expect(replies.last).to eq('Acknowledged: ABC789')
      end
    end

    describe 'when there are no acknowledgable incidents' do
      it 'shows a warning' do
        expect(Pagerduty).to receive(:new) { no_incidents }
        send_command('pager ack all')
        expect(replies.last).to eq('No triggered, open, or acknowledged ' \
                                   'incidents')
      end
    end
  end

  describe '#ack_mine' do
    describe 'when there are acknowledgable incidents for the user' do
      it 'shows them as acknowledged' do
        bar = Lita::User.create(123, name: 'bar')
        expect(Pagerduty).to(receive(:new).twice { incidents })
        send_command('pager identify bar@example.com', as: bar)
        send_command('pager ack mine', as: bar)
        expect(replies.last).to eq('Acknowledged: ABC789')
      end
    end

    describe 'when there are no acknowledgable incidents for the user' do
      it 'shows a warning' do
        foo = Lita::User.create(123, name: 'foo')
        expect(Pagerduty).to receive(:new) { incidents }
        send_command('pager identify foo@example.com', as: foo)
        send_command('pager ack mine', as: foo)
        expect(replies.last).to eq('You have no triggered, open, or ' \
                                   'acknowledged incidents')
      end
    end

    describe 'when the user has not identified themselves' do
      it 'shows a warning' do
        send_command('pager ack mine')
        expect(replies.last).to eq('You have not identified yourself (use ' \
                                   'the help command for more info)')
      end
    end
  end

  describe '#ack' do
    describe 'when the incident has not been acknowledged' do
      it 'shows the acknowledgement' do
        expect(Pagerduty).to receive(:new) { new_incident }
        send_command('pager ack ABC123')
        expect(replies.last).to eq('ABC123: Incident acknowledged')
      end
    end

    describe 'when the incident has already been acknowledged' do
      it 'shows the warning' do
        expect(Pagerduty).to receive(:new) { acknowledged_incident }
        send_command('pager ack ABC123')
        expect(replies.last).to eq('ABC123: Incident already acknowledged')
      end
    end

    describe 'when the incident does not exist' do
      it 'shows an error' do
        expect(Pagerduty).to receive(:new) { no_incident }
        send_command('pager ack ABC123')
        expect(replies.last).to eq('ABC123: Incident not found')
      end
    end

    describe 'when the incident cannot be acknowledged' do
      it 'shows that its unable to acknowledge' do
        expect(Pagerduty).to receive(:new) { unable_to_ack_incident }
        send_command('pager ack ABC123')
        expect(replies.last).to eq('ABC123: Unable to acknowledge incident')
      end
    end
  end
end
