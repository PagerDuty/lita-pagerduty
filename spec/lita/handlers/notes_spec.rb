require 'spec_helper'

describe Lita::Handlers::Pagerduty, lita_handler: true do
  context 'notes ABC123' do
    it do
      is_expected.to route_command('pager notes ABC123').to(:notes)
    end

    it 'incident not found' do
      expect_any_instance_of(Pagerduty).to receive(:get_notes_by_incident_id).and_raise(Exceptions::IncidentNotFound)
      send_command('pager notes ABC123')
      expect(replies.last).to eq('ABC123: Incident not found')
    end

    it 'notes list' do
      expect_any_instance_of(Pagerduty).to receive(:get_notes_by_incident_id).and_return([
        { content: 'Content', user: { summary: 'foo' } }
      ])
      send_command('pager notes ABC123')
      expect(replies.last).to eq('ABC123: Content (foo)')
    end

    it 'empty notes list' do
      expect_any_instance_of(Pagerduty).to receive(:get_notes_by_incident_id).and_raise(Exceptions::NotesEmptyList)
      send_command('pager notes ABC123')
      expect(replies.last).to eq('ABC123: No notes')
    end
  end
end
