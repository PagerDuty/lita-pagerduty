require 'spec_helper'

describe Lita::Handlers::PagerdutyNote, lita_handler: true do
  it do
    is_expected.to route_command('pager notes ABC123').to(:notes)
    is_expected.to route_command('pager note ABC123 some text').to(:note)
  end
end
