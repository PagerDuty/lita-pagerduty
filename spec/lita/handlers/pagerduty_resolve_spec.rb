require 'spec_helper'

describe Lita::Handlers::PagerdutyResolve, lita_handler: true do
  it do
    is_expected.to route_command('pager resolve all').to(:resolve_all)
    is_expected.to route_command('pager resolve mine').to(:resolve_mine)
    is_expected.to route_command('pager resolve ABC123').to(:resolve)
  end
end
