module Commands
  class Forget
    include Base

    def call
      store.get_user message
      store.forget_user message
      response message: 'forget.complete'
    rescue Exceptions::UserNotIdentified
      response message: 'forget.unknown'
    end
  end
end
