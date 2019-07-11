# frozen_string_literal: true

module Commands
  module Base
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        attr_reader :message
        attr_reader :data
        attr_reader :pagerduty
        attr_reader :store
      end
    end

    module ClassMethods
      def call(message, pagerduty, store)
        new(message, pagerduty, store).tap(&:call).data
      end
    end

    def initialize(message, pagerduty, store)
      @message = message
      @pagerduty = pagerduty
      @store = store
      @data = nil
    end

    def response(obj)
      @data = obj
    end

    def format_notes(notes, incident_id)
      notes.map { |note| format_note(note, incident_id) }
    end

    def format_note(note, incident_id)
      {
        message: 'note.show',
        params: {
          id: incident_id,
          content: note[:content],
          user: note[:user][:summary]
        }
      }
    end

    def format_incidents(incidents)
      incidents.map { |incident| format_incident(incident) }
    end

    def format_incident(incident)
      assignee = (incident.fetch(:assignments, []).first || {})
                 .fetch(:assignee, {})
                 .fetch(:summary, 'none')
      {
        message: 'incident.info',
        params: {
          id: incident[:id], subject: incident[:title],
          assigned: assignee.inspect, url: incident[:html_url]
        }
      }
    end

    def current_user
      @current_user ||= pagerduty.get_users(query: store.get_user(message))
                                 .first
    end

    def pagerduty
      @pagerduty ||= ::Pagerduty.new(
        http,
        config.api_key,
        config.email,
        config.teams
      )
    end

    def store
      @store ||= Store.new(redis)
    end
  end
end
