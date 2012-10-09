require 'users_services'

class SessionsController < Devise::SessionsController
  
  include UsersServices
  
  prepend_before_filter :min_last_request_at, :only => :destroy

  private

  def min_last_request_at
    current_user.update_attribute(:last_request_at, Time.at(0))
  end
    
end
