require 'spec_helper'

describe PDTime do
  it 'get_last_day_of_month' do
    expect(PDTime.get_last_day_of_month(10)).to eq(31)
    expect(PDTime.get_last_day_of_month(11)).to eq(30)
    expect(PDTime.get_last_day_of_month(12)).to eq(31)
  end
end
