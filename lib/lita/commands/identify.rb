# frozen_string_literal: true

module Commands
  class Identify
    include Base

    def call
      store.get_user message
      response message: 'identify.already'
    rescue Exceptions::UserNotIdentified
      store.remember_user message
      response message: 'identify.complete'
    end
  end
end
