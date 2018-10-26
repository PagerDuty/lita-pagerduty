require 'spec_helper'

describe Lita::Handlers::Pagerduty, lita_handler: true do
  context 'resolve ABC123' do
    it do
      is_expected.to route_command('pager resolve ABC123').to(:resolve)
    end

    it 'not found' do
      expect_any_instance_of(Pagerduty).to receive(:manage_incidents).and_raise(Exceptions::IncidentManageUnsuccess)
      send_command('pager resolve ABC123')
      expect(replies.last).to be_nil
    end

    it 'found' do
      expect_any_instance_of(Pagerduty).to receive(:manage_incidents)
      send_command('pager resolve ABC123')
      expect(replies.last).to eq 'Resolved: ABC123'
    end
  end
end
