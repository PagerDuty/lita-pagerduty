require 'spec_helper'

describe Lita::Handlers::PagerdutyNote, lita_handler: true do
  include_context 'basic fixtures'

  it do
    is_expected.to route_command('pager notes ABC123').to(:notes)
    is_expected.to route_command('pager note ABC123 some text').to(:note)
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
end
