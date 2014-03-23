require 'spec_helper'
require 'pagerduty'

describe Lita::Handlers::Pagerduty, lita_handler: true do
  let(:no_incidents) do
    client = double
    expect(client).to receive(:get_incident) { 'No results' }
    client
  end

  let(:new_incident) do
    client = double
    expect(client).to receive(:get_incident) do
      double(
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

  it { routes_command('who\'s on call').to(:whos_on_call) }
  it { routes_command('who\'s on call?').to(:whos_on_call) }
  it { routes_command('pager incidents all').to(:incidents_all) }
  it { routes_command('pager incidents mine').to(:incidents_mine) }
  it { routes_command('pager incident ABC123').to(:incident) }
  it { routes_command('pager notes ABC123').to(:notes) }
  it { routes_command('pager note ABC123 some text').to(:note) }
  it { routes_command('pager ack all').to(:ack_all) }
  it { routes_command('pager ack mine').to(:ack_mine) }
  it { routes_command('pager ack ABC123').to(:ack) }
  it { routes_command('pager resolve all').to(:resolve_all) }
  it { routes_command('pager resolve mine').to(:resolve_mine) }
  it { routes_command('pager resolve ABC123').to(:resolve) }

  describe '.default_config' do
    it 'sets api_key to nil' do
      expect(Lita.config.handlers.pagerduty.api_key).to be_nil
    end

    it 'sets subdomain to nil' do
      expect(Lita.config.handlers.pagerduty.subdomain).to be_nil
    end
  end

  describe 'without valid config' do
    it 'should error out on any command' do
      expect { send_command('pager ack ABC123') }.to raise_error('Bad config')
    end
  end

  describe 'with valid config' do
    before do
      Lita.config.handlers.pagerduty.api_key = 'foo'
      Lita.config.handlers.pagerduty.subdomain = 'bar'
    end

    describe '#whos_on_call' do
      describe 'when someone is on call' do
      end

      describe 'when no one is on call' do
      end
    end

    describe '#incidents_all' do
      describe 'when there are open incidents' do
      end

      describe 'when there are no open incidents' do
      end
    end

    describe '#incidents_mine' do
      describe 'when there are open incidents for the user' do
      end

      describe 'when there are no open incidents for the user' do
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
          expect(Pagerduty).to receive(:new) { no_incidents }
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
          expect(Pagerduty).to receive(:new) { no_incidents }
          send_command('pager notes ABC123')
          expect(replies.last).to eq('ABC123: Incident not found')
        end
      end
    end

    describe '#note' do
      describe 'when the incident exists' do
      end

      describe 'when the incident does not exist' do
      end
    end

    describe '#ack_all' do
      describe 'when there are acknowledgable incidents' do
      end

      describe 'when there are no acknowledgable incidents' do
      end
    end

    describe '#ack_mine' do
      describe 'when there are acknowledgable incidents for the user' do
      end

      describe 'when there are no acknowledgable incidents for the user' do
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
          expect(Pagerduty).to receive(:new) { no_incidents }
          send_command('pager ack ABC123')
          expect(replies.last).to eq('ABC123: Incident not found')
        end
      end
    end

    describe '#resolve_all' do
      describe 'when there are resolvable incidents' do
      end

      describe 'when there are no resolvable incidents' do
      end
    end

    describe '#resolve_mine' do
      describe 'when there are resolvable incidents for the user' do
      end

      describe 'when there are no resolvable incidents for the user' do
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
          expect(Pagerduty).to receive(:new) { no_incidents }
          send_command('pager resolve ABC123')
          expect(replies.last).to eq('ABC123: Incident not found')
        end
      end
    end
  end
end
