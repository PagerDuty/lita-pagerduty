require 'spec_helper'

describe Lita::Handlers::PagerdutyUtility, lita_handler: true do
  let(:no_incident) do
    client = double
    expect(client).to receive(:get_incident) { 'No results' }
    client
  end

  let(:no_incidents) do
    client = double
    expect(client).to receive(:incidents) do
      double(
        incidents: []
      )
    end
    client
  end

  let(:incidents) do
    client = double
    expect(client).to receive(:incidents) do
      double(
        incidents: [
          double(
            id: 'ABC123',
            status: 'resolved',
            trigger_summary_data: double(subject: 'something broke'),
            assigned_to_user: double(email: 'foo@example.com')
          ),
          double(
            id: 'ABC789',
            status: 'triggered',
            trigger_summary_data: double(subject: 'Still broke'),
            assigned_to_user: double(email: 'bar@example.com')
          )
        ]
      )
    end
    allow(client).to receive(:get_incident) do
      double(
        status: 'triggered',
        trigger_summary_data: double(subject: 'Still broke'),
        assigned_to_user: double(email: 'bar@example.com'),
        acknowledge: { 'id' => 'ABC789', 'status' => 'acknowledged' },
        resolve: { 'id' => 'ABC789', 'status' => 'resolved' },
        notes: double(notes: [])
      )
    end
    client
  end

  let(:new_incident) do
    client = double
    expect(client).to receive(:get_incident) do
      double(
        id: 'ABC123',
        status: 'triggered',
        trigger_summary_data: double(subject: 'something broke'),
        assigned_to_user: double(email: 'foo@example.com'),
        acknowledge: { 'id' => 'ABC123', 'status' => 'acknowledged' },
        resolve: { 'id' => 'ABC123', 'status' => 'resolved' },
        notes: double(notes: [])
      )
    end
    client
  end

  let(:acknowledged_incident) do
    client = double
    expect(client).to receive(:get_incident) do
      double(
        status: 'acknowledged',
        trigger_summary_data: double(subject: 'something broke'),
        assigned_to_user: double(email: 'foo@example.com'),
        acknowledge: { 'error' =>
          { 'message' => 'Incident Already Acknowledged', 'code' => 1002 }
        },
        resolve:  { 'id' => 'ABC123', 'status' => 'resolved' },
        notes: double(notes: [])
      )
    end
    client
  end

  let(:resolved_incident) do
    client = double
    expect(client).to receive(:get_incident) do
      double(
        status: 'resolved',
        trigger_summary_data: double(subject: 'something broke'),
        assigned_to_user: double(email: 'foo@example.com'),
        notes: double(notes: [])
      )
    end
    client
  end

  let(:incident_with_notes) do
    client = double
    expect(client).to receive(:get_incident) do
      double(
        id: 'ABC123',
        status: 'resolved',
        trigger_summary_data: double(subject: 'something broke'),
        assigned_to_user: double(email: 'foo@example.com'),
        notes: double(
          notes: [double(content: 'Hi!',
                         user: double(email: 'foo@example.com'))]
        )
      )
    end
    client
  end

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

  describe '#incidents_all' do
    describe 'when there are open incidents' do
      it 'shows a list of incidents' do
        expect(Pagerduty).to receive(:new) { incidents }
        send_command('pager incidents all')
        expect(replies.last).to eq('ABC789: "Still broke", assigned to: '\
                                   'bar@example.com')
      end
    end

    describe 'when there are no open incidents' do
      it 'shows a warning' do
        expect(Pagerduty).to receive(:new) { no_incidents }
        send_command('pager incidents all')
        expect(replies.last).to eq('No triggered, open, or acknowledged ' \
                                   'incidents')
      end
    end
  end

  describe '#incidents_mine' do
    describe 'when there are open incidents for the user' do
      it 'shows a list of incidents' do
        bar = Lita::User.create(123, name: 'bar')
        expect(Pagerduty).to receive(:new) { incidents }
        send_command('pager identify bar@example.com', as: bar)
        send_command('pager incidents mine', as: bar)
        expect(replies.last).to eq('ABC789: "Still broke", assigned to: ' \
                                   'bar@example.com')
      end
    end

    describe 'when there are no open incidents for the user' do
      it 'shows no incidents' do
        foo = Lita::User.create(123, name: 'foo')
        expect(Pagerduty).to receive(:new) { incidents }
        send_command('pager identify foo@example.com', as: foo)
        send_command('pager incidents mine', as: foo)
        expect(replies.last).to eq('You have no triggered, open, or ' \
                                   'acknowledged incidents')
      end
    end

    describe 'when the user has not identified themselves' do
      it 'shows a warning' do
        send_command('pager incidents mine')
        expect(replies.last).to eq('You have not identified yourself (use ' \
                                   'the help command for more info)')
      end
    end
  end

  describe '#incident' do
    describe 'when the incident exists' do
      it 'shows incident details' do
        expect(Pagerduty).to receive(:new) { new_incident }
        send_command('pager incident ABC123')
        expect(replies.last).to eq('ABC123: "something broke", ' \
                                   'assigned to: foo@example.com')
      end
    end

    describe 'when the incident does not exist' do
      it 'shows an error' do
        expect(Pagerduty).to receive(:new) { no_incident }
        send_command('pager incident ABC123')
        expect(replies.last).to eq('ABC123: Incident not found')
      end
    end
  end

  describe '#notes' do
    describe 'when the incident has notes' do
      it 'shows incident notes' do
        expect(Pagerduty).to receive(:new) { incident_with_notes }
        send_command('pager notes ABC123')
        expect(replies.last).to eq('ABC123: Hi! (foo@example.com)')
      end
    end

    describe 'when the incident doesnt have notes' do
      it 'shows no notes' do
        expect(Pagerduty).to receive(:new) { new_incident }
        send_command('pager notes ABC123')
        expect(replies.last).to eq('ABC123: No notes')
      end
    end

    describe 'when the incident does not exist' do
      it 'shows an error' do
        expect(Pagerduty).to receive(:new) { no_incident }
        send_command('pager notes ABC123')
        expect(replies.last).to eq('ABC123: Incident not found')
      end
    end
  end

  describe '#note' do
    it 'shows a warning' do
      send_command('pager note ABC123 some text')
      expect(replies.last).to eq('Not implemented yet.')
    end
  end

  describe '#ack_all' do
    describe 'when there are acknowledgable incidents' do
      it 'shows them as acknowledged' do
        expect(Pagerduty).to receive(:new).twice { incidents }
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
        expect(Pagerduty).to receive(:new).twice { incidents }
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
