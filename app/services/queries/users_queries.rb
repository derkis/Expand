module UsersQueries
  
  def self.users_online_for_current_user_since(time, current_user)
    User.all(
    	:conditions => [ "last_request_at > ? AND NOT email = ?", time, current_user.email ], :order => :id
    )
  end

end