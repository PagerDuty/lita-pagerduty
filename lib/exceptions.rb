module Exceptions
  class SchedulesEmptyList < StandardError; end
  class IncidentsEmptyList < StandardError; end
  class UsersEmptyList < StandardError; end
  class NotesEmptyList < StandardError; end
  class IncidentManageUnsuccess < StandardError; end
  class OverrideUnsuccess < StandardError; end
  class IncidentNotFound < StandardError; end
  class UserNotIdentified < StandardError; end
  class NoOncallUser < StandardError; end
end
