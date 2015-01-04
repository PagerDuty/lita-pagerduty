require 'spec_helper'

describe Lita::Handlers::PagerdutyAck, lita_handler: true do
  it do
    is_expected.to route_command('pager ack all').to(:ack_all)
    is_expected.to route_command('pager ack mine').to(:ack_mine)
    is_expected.to route_command('pager ack ABC123').to(:ack)
  end
end
