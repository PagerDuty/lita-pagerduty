require 'spec_helper'

describe Lita::Handlers::Pagerduty, lita_handler: true do
  context 'pager forget' do
    it do
      is_expected.to route_command('pager forget').to(:forget)
    end

    it 'existing' do
      user = Lita::User.create(123, name: 'foo')
      send_command('pager identify foo@example.com', as: user)
      send_command('pager forget', as: user)
      expect(replies.last).to eq('Your email has now been forgotten.')
    end

    it 'non-existing' do
      user = Lita::User.create(123, name: 'foo')
      send_command('pager forget', as: user)
      expect(replies.last).to eq('No email on record for you.')
    end
  end
end
