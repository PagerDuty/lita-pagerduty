# frozen_string_literal: true

module Exceptions
  class SchedulesEmptyList < StandardError; end
  class IncidentsEmptyList < StandardError; end
  class UsersEmptyList < StandardError; end
  class NotesEmptyList < StandardError; end
  class IncidentManageUnsuccess < StandardError; end
  class OverrideUnsuccess < StandardError; end
  class IncidentNotFound < StandardError; end
  class ScheduleNotFound < StandardError; end
  class UserNotIdentified < StandardError; end
  class NoOncallUser < StandardError; end
  class NoUser < StandardError; end
  class PeriodNotProvided < StandardError; end
  class NoTimeZone < StandardError; end
  class UnknownUnit < StandardError; end
end
