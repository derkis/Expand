module SessionsWebservices
  
  def users_online
    users_online = current_user.get_other_users_since(15.minutes.ago)
    respond_to do |format| 
      format.json { render :json => users_online.to_json(:only => [:id, :email]) }
      format.all { not_found() }
    end
  end
  
end