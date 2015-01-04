require 'spec_helper'

describe Lita::Handlers::PagerdutyIncident, lita_handler: true do
  it do
    is_expected.to route_command('pager incidents all').to(:incidents_all)
    is_expected.to route_command('pager incidents mine').to(:incidents_mine)
    is_expected.to route_command('pager incident ABC123').to(:incident)
  end
end
