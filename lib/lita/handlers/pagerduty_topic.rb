# Lita-related code
module Lita
  # Plugin-related code
  module Handlers
    # Topic updating
    class PagerdutyTopic < Handler
      include ::PagerdutyHelper::Utility

      namespace 'Pagerduty'

      on :loaded, :create_updaters

      # Start one `every` thread for each room to update
      def create_updaters(_)
        config.topic_rooms.each do |room, schedules|
          log.info("Adding timer job to update topic of #{room}")
          every(config.topic_frequency) { |_| update_topic(room, schedules) }
        end
      end

      # Update the topic in the given room with the users who are currently
      # on-call for each schedule
      def update_topic(room_name, schedules)
        log.info("Updating #{room_name} topic using #{schedules}")
        oncalls = fetch_oncalls_from(schedules)
        topic = generate_topic(oncalls)

        old_topic = current_topic(room_name)
        log.info "old topic: #{old_topic}"
        if topic == old_topic
          log.info 'Old topic matches new, nothing to do here'
          return
        end

        log.info("Topic I generated: #{topic}")
        room = Lita::Room.fuzzy_find(room_name)
        log.info "Would set topic in #{room.name} to #{topic}"
        robot.set_topic(Lita::Source.new(room: room), topic)
      rescue Exception => e
        log.error "Unable to update topic for #{room_name} with #{schedules}: #{e}"
        log.error e.backtrace
      end

      def fetch_oncalls_from(schedules)
        oncalls = []
        schedules.map do |schedule|
          oncalls << lookup_on_call_user(schedule_by_name(schedule).id)
        end

        oncalls = ['no one'] if oncalls.empty?
        oncalls
      end

      def current_topic(room_name)
        # TODO: get rid of this hack
        # Upstream Lita has a `set_topic` method but no `get_topic`, while adapters
        # generally have the get in their own specific way. We're only going to
        # support Slack for now until upstream is fixed.
        raise 'Your adapter is not supported' if Lita.config.robot.adapter != :slack

        topic = ''

        room = Lita::Room.fuzzy_find(room_name)
        unless room.nil?
          # Raw-ish slack API call. This is gross.
          # Since we're using Slack, we're assuming that lita-slack is loaded.
          slack_channel = robot.chat_service.api.channels_info(room.id)
          topic = slack_channel['channel']['topic']['value']
        end
        topic
      end

      def generate_topic(oncalls)
        # If we know the user's email, transform the full name into the chat user name
        usernames = oncalls.map { |u| user_name(u) }

        if oncalls.length == 1
          t('on_call_topic.singular', name: usernames.first)
        else
          t('on_call_topic.plural', names: usernames.join(' / '))
        end
      end

      def user_name(oncall)
        user = chat_user(oncall)
        if user
          '@' + user.mention_name
        else
          oncall.name
        end
      end

      def chat_user(pd_user)
        Lita::User.find_by_id(fetch_user_by_email(pd_user.email))
      end
    end

    Lita.register_handler(PagerdutyTopic)
  end
end
