require 'spec_helper'

describe Lita::Handlers::Pagerduty, lita_handler: true do
  context 'pager identify foobar@example.com' do
    it do
      is_expected.to route_command('pager identify foobar@example.com').to(:identify)
    end

    it 'identify first time' do
      user = Lita::User.create(123, name: 'foo')
      send_command('pager identify foo@example.com', as: user)
      expect(replies.last).to eq('You have now been identified.')
    end

    it 'identify existing user' do
      user = Lita::User.create(123, name: 'foo')
      send_command('pager identify foo@example.com', as: user)
      send_command('pager identify foo@example.com', as: user)
      expect(replies.last).to eq('You have already been identified!')
    end
  end
end
