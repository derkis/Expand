require 'users_queries'

module UsersServices
  
  include UsersQueries

  def users_online
    users_online = UsersQueries.users_online_for_current_user_since(15.minutes.ago, current_user)
    respond_to do |format| 
      format.json { render :json => users_online.to_json(:only => [:id, :email]) }
      format.all { not_found() }
    end
  end
  
end