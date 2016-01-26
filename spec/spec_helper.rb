require 'simplecov'
require 'coveralls'
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start { add_filter '/spec/' }

require 'lita-pagerduty'
require 'lita/rspec'

Lita.version_3_compatibility_mode = false

RSpec.configure do |config|
  config.before do
    registry.register_handler(Lita::Handlers::PagerdutyAck)
    registry.register_handler(Lita::Handlers::PagerdutyIncident)
    registry.register_handler(Lita::Handlers::PagerdutyNote)
    registry.register_handler(Lita::Handlers::PagerdutyResolve)
    registry.register_handler(Lita::Handlers::PagerdutyUtility)
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.default_formatter = 'doc' if config.files_to_run.one?
  config.order = :random

  Kernel.srand config.seed
end

RSpec.shared_context 'basic fixtures' do
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
            html_url: 'https://acme.pagerduty.com/incidents/ABC123',
            trigger_summary_data: double(subject: 'something broke'),
            assigned_to_user: double(email: 'foo@example.com')
          ),
          double(
            id: 'ABC789',
            status: 'triggered',
            html_url: 'https://acme.pagerduty.com/incidents/ABC789',
            trigger_summary_data: double(subject: 'Still broke'),
            assigned_to_user: double(email: 'bar@example.com')
          )
        ]
      )
    end
    allow(client).to receive(:get_incident) do
      double(
        status: 'triggered',
        html_url: 'https://acme.pagerduty.com/incidents/ABC789',
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
        html_url: 'https://acme.pagerduty.com/incidents/ABC123',
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
        html_url: 'https://acme.pagerduty.com/incidents/ABC123',
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
        html_url: 'https://acme.pagerduty.com/incidents/ABC123',
        trigger_summary_data: double(subject: 'something broke'),
        assigned_to_user: double(email: 'foo@example.com'),
        notes: double(notes: [])
      )
    end
    client
  end

  let(:unable_to_resolve_incident) do
    client = double
    expect(client).to receive(:get_incident) do
      double(
        status: 'notresolved',
        html_url: 'https://acme.pagerduty.com/incidents/ABC123',
        resolve:  { 'id' => 'ABC123', 'status' => 'notresolved' }
      )
    end
    client
  end

  let(:unable_to_ack_incident) do
    client = double
    expect(client).to receive(:get_incident) do
      double(
        status: 'notacked',
        html_url: 'https://acme.pagerduty.com/incidents/ABC123',
        acknowledge: { 'error' => {} },
        resolve:  { 'id' => 'ABC123', 'status' => 'notacked' }
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
        html_url: 'https://acme.pagerduty.com/incidents/ABC123',
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

  let(:incident_with_long_id) do
    client = double
    expect(client).to receive(:get_incident) do
      double(
        id: 'ABC123456789',
        status: 'triggered',
        trigger_summary_data: double(subject: 'something broke'),
        assigned_to_user: double(email: 'foo@example.com')
      )
    end
    client
  end
end
