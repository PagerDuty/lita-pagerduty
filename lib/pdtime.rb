# frozen_string_literal: true

require 'tzinfo'

class PDTime
  def self.get_offset_for_timezone(timezone)
    if timezone.nil?
      utc_offset = 0
    else
      timezone = ::TZInfo::Timezone.get(timezone)
      current_period = timezone.current_period
      utc_offset = current_period.utc_total_offset_rational.numerator
    end

    utc_offset
  end

  def self.get_time_range(timezone)
    utc_offset = get_offset_for_timezone(timezone)

    local = DateTime.now
    now_begin_unformatted = local.new_offset(Rational(utc_offset, 24))
    now_begin = now_begin_unformatted.strftime('%Y-%m-%dT%H:%M:00')

    now_end_unformatted = local.new_offset(Rational(utc_offset, 24))
    now_end = now_end_unformatted.strftime('%Y-%m-%dT%H:%M:01')

    {
      'now_begin' => now_begin,
      'now_end' => now_end
    }
  end

  def self.get_last_day_of_month(month_number)
    local = DateTime.now
    now_unformatted = local.new_offset(Rational(0, 24))
    year = now_unformatted.strftime('%Y').to_i

    Date.civil(year, month_number, -1).strftime('%d').to_i
  end
end
