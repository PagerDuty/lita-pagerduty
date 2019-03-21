module Lita
  module Handlers
    class Pagerduty < Handler
      namespace 'Pagerduty'
      config :api_key, required: true
      config :email, required: true
      config :teams, required: false

      COMMANDS_PATH = File.read("#{File.dirname(__FILE__)}/commands.yml")
      COMMANDS = YAML.safe_load(COMMANDS_PATH)
      COMMANDS.each do |command|
        route(
          /#{command['pattern']}/,
          command['method'].to_sym,
          command: true,
          help: {
            t("help.#{command['method']}.syntax") =>
              t("help.#{command['method']}.desc")
          }
        )
      end

      def method_missing(method, message)
        super if COMMANDS.map { |i| i['method'] }.include? method
        response = Object.const_get(
          'Commands::' << method.to_s.split('_').map(&:capitalize).join
        ).send(:call, message, pagerduty, store)
        handle_response(message, response) if response
      end

      def respond_to_missing?(method, include_private = false)
        COMMANDS.map { |i| i['method'] }.include?(method) || super
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

      def handle_response(message, response)
        message.reply case response
                      when String
                        response
                      when Hash
                        t response[:message], response[:params]
                      when Array
                        response.map { |item| t item[:message], item[:params] }
                                .join("\n")
                      end
      end

      Lita.register_handler(self)
    end
  end
end
