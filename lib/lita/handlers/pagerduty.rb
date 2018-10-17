module Lita
  module Handlers
    class Pagerduty < Handler
      INCIDENT_ID_PATTERN = /(?<incident_id>[a-zA-Z0-9+]+)/
      EMAIL_PATTERN = /(?<email>[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+)/i

      namespace 'Pagerduty'
      config :api_key, required: true
      config :email, required: true

      route(/^pager\sidentify\s#{EMAIL_PATTERN}$/, :identify, command: true, help: { t('help.identify.syntax') => t('help.identify.desc') })
      route(/^pager\sforget$/, :forget, command: true, help: { t('help.forget.syntax') => t('help.forget.desc') })
      route(/^pager\sincidents\sall$/, :incidents_all, command: true, help: { t('help.incidents_all.syntax') => t('help.incidents_all.desc') })
      route(/^pager\sincidents\smine$/, :incidents_mine, command: true, help: { t('help.incidents_mine.syntax') => t('help.incidents_mine.desc') })
      route(/^pager\sincident\s#{INCIDENT_ID_PATTERN}$/, :incident, command: true, help: { t('help.incident.syntax') => t('help.incident.desc') })
      route(/^pager\snotes\s#{INCIDENT_ID_PATTERN}$/, :notes, command: true, help: { t('help.notes.syntax') => t('help.notes.desc') })
      route(/^pager\sack\sall$/, :ack_all, command: true, help: { t('help.ack_all.syntax') => t('help.ack_all.desc') })
      route(/^pager\sack\smine$/, :ack_mine, command: true, help: { t('help.ack_mine.syntax') => t('help.ack_mine.desc') })
      route(/^pager\sack\s#{INCIDENT_ID_PATTERN}$/, :ack, command: true, help: { t('help.ack.syntax') => t('help.ack.desc') })
      route(/^pager\sresolve\sall$/, :resolve_all, command: true, help: { t('help.resolve_all.syntax') => t('help.resolve_all.desc') })
      route(/^pager\sresolve\smine$/, :resolve_mine, command: true, help: { t('help.resolve_mine.syntax') => t('help.resolve_mine.desc') })
      route(/^pager\sresolve\s#{INCIDENT_ID_PATTERN}$/, :resolve, command: true, help: { t('help.resolve.syntax') => t('help.resolve.desc') })
      route(/^pager\soncall$/, :on_call_list, command: true, help: { t('help.on_call_list.syntax') => t('help.on_call_list.desc') })
      route(/^pager\soncall\s(.*)$/, :on_call_lookup, command: true, help: { t('help.on_call_lookup.syntax') => t('help.on_call_lookup.desc') })
      route(/^pager\s+me\s+(.+?)\s+(\d+)m?$/, :pager_me, command: true, help: { t('help.pager_me.syntax') => t('help.pager_me.desc') })

      def pager_me(response)
        email = redis.get("user_#{response.user.id}")
        return response.reply(t('identify.missing')) unless email
        schedule_name = response.match_data[1].strip
        schedule = pagerduty.get_schedules({ query: schedule_name }).first
        return response.reply(t('on_call_lookup.no_matching_schedule', schedule_name: schedule_name)) unless schedule
        user = pagerduty.get_users({ query: email }).first
        return response.reply(t('identify.unrecognised')) unless user
        override = pagerduty.override(schedule[:id], user[:id], response.match_data[2].strip.to_i)
        return response.reply(t('pager_me.failure')) unless override
        response.reply(t('pager_me.success', name: override[:user][:summary], email: user[:email], finish: override[:end]))
      end

      def on_call_list(response)
        schedules = pagerduty.get_schedules
        return response.reply(t('on_call_list.no_schedules_found')) if schedules.empty?
        schedule_list = schedules.map{ |i| i[:name] }.join("\n")
        response.reply(t('on_call_list.response', schedules: schedule_list))
      end

      def on_call_lookup(response)
        schedule_name = response.match_data[1].strip
        schedule = pagerduty.get_schedules({ query: schedule_name }).first
        return response.reply(t('on_call_lookup.no_matching_schedule', schedule_name: schedule_name)) unless schedule
        user = pagerduty.get_oncalls('schedule_ids[]': schedule[:id], 'include[]': 'users').first.fetch(:user, nil)
        return response.reply(t('on_call_lookup.no_one_on_call', schedule_name: schedule_name)) unless user
        response.reply(t('on_call_lookup.response', name: user[:summary], email: user[:email], schedule_name: schedule[:name]))
      end

      def resolve_all(response)
        incidents = pagerduty.get_incidents
        return response.reply(t('incident.none')) if incidents.empty?
        ids = incidents.map { |i| i[:id] }
        result = pagerduty.resolve_incidents(ids)
        return unless result.status == 200
        response.reply(t('all.resolved', list: ids.join(', ')))
      end

      def resolve_mine(response)
        email = redis.get("user_#{response.user.id}")
        user = pagerduty.get_users({ query: email }).first
        return response.reply(t('incident.none_mine')) unless user
        incidents = pagerduty.get_incidents('user_ids[]': user[:id])
        return response.reply(t('incident.none_mine')) if incidents.empty?
        ids = incidents.map { |i| i[:id] }
        result = pagerduty.resolve_incidents(ids)
        return unless result.status == 200
        response.reply(t('all.resolved', list: ids.join(', ')))
      end

      def resolve(response)
        incident_id = response.match_data['incident_id']
        return if (incident_id.downcase == 'all') || (incident_id.downcase == 'mine')
        result = pagerduty.resolve_incidents([incident_id])
        return unless result.status == 200
        response.reply(t('all.resolved', list: incident_id.to_s))
      end

      def ack_all(response)
        incidents = pagerduty.get_incidents
        return response.reply(t('incident.none')) if incidents.empty?
        ids = incidents.map { |i| i[:id] }
        result = pagerduty.acknowledge_incidents(ids)
        return unless result.status == 200
        response.reply(t('all.acknowledged', list: ids.join(', ')))
      end

      def ack_mine(response)
        email = redis.get("user_#{response.user.id}")
        user = pagerduty.get_users({ query: email }).first
        return response.reply(t('incident.none_mine')) unless user
        incidents = pagerduty.get_incidents('user_ids[]': user[:id])
        return response.reply(t('incident.none_mine')) if incidents.empty?
        ids = incidents.map { |i| i[:id] }
        result = pagerduty.acknowledge_incidents(ids)
        return unless result.status == 200
        response.reply(t('all.acknowledged', list: ids.join(', ')))
      end

      def ack(response)
        incident_id = response.match_data['incident_id']
        return if (incident_id.downcase == 'all') || (incident_id.downcase == 'mine')
        result = pagerduty.acknowledge_incidents([incident_id])
        return unless result.status == 200
        response.reply(t('all.acknowledged', list: incident_id.to_s))
      end

      def identify(response)
        email = response.match_data['email']
        stored_user = redis.get("user_#{response.user.id}")
        return response.reply(t('identify.already')) if stored_user
        redis.set("user_#{response.user.id}", email)
        response.reply(t('identify.complete'))
      end

      def forget(response)
        stored_user = redis.get("user_#{response.user.id}")
        return response.reply(t('forget.unknown')) unless stored_user
        redis.del("user_#{response.user.id}")
        response.reply(t('forget.complete'))
      end

      def incidents_all(response)
        incidents = pagerduty.get_incidents
        return response.reply(t('incident.none')) if incidents.empty?
        message = incidents.map do |incident|
          assignee = (incident.fetch(:assignments, []).first || {}).fetch(:assignee, {}).fetch(:summary, 'none')
          t('incident.info', id: incident[:id],
                             subject: incident[:title],
                             assigned: assignee.inspect,
                             url: incident[:html_url])
        end
        response.reply(message)
      end

      def incidents_mine(response)
        email = redis.get("user_#{response.user.id}")
        user = pagerduty.get_users({ query: email }).first
        return response.reply(t('incident.none_mine')) unless user
        incidents = pagerduty.get_incidents('user_ids[]': user[:id])
        return response.reply(t('incident.none')) if incidents.empty?
        message = incidents.map do |incident|
          assignee = (incident.fetch(:assignments, []).first || {}).fetch(:assignee, {}).fetch(:summary, 'none')
          t('incident.info', id: incident[:id],
                                 subject: incident[:title],
                                 assigned: assignee.inspect,
                                 url: incident[:html_url])
        end
        response.reply(message)
      end

      def incident(response)
        incident_id = response.match_data['incident_id']
        incident = pagerduty.get_incident(incident_id)
        return response.reply(t('incident.not_found', id: incident_id)) unless incident
        assignee = (incident.fetch(:assignments, []).first || {}).fetch(:assignee, {}).fetch(:summary, 'none')
        response.reply(
          t('incident.info', id: incident[:id],
                             subject: incident[:title],
                             assigned: assignee.inspect,
                             url: incident[:html_url])
        )
      end

      def notes(response)
        incident_id = response.match_data['incident_id']
        notes = pagerduty.get_notes_by_incident_id(incident_id)
        return response.reply("#{incident_id}: No notes") if notes.empty?
        message = notes.map do |note|
          t('note.show', id: incident_id, content: note[:content], user: note[:user][:summary])
        end
        response.reply(message)
      rescue => e
        response.reply(t('incident.not_found', id: incident_id))
      end

      private

      def pagerduty
        @pagerduty ||= ::PagerDuty.new(http, config.api_key, config.email)
      end

      Lita.register_handler(self)
    end
  end
end
