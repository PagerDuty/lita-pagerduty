class Store
  def initialize(redis)
    @redis = redis
  end

  def get_user(response)
    email = @redis.get("user_#{response.user.id}")
    raise Exceptions::UserNotIdentified unless email

    email
  end

  def remember_user(response)
    @redis.set("user_#{response.user.id}", response.match_data['email'])
  end

  def forget_user(response)
    @redis.del("user_#{response.user.id}")
  end
end
