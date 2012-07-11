require 'sessions_webservices'

class SessionsController < Devise::SessionsController
  
  include SessionsWebservices
  
  prepend_before_filter :min_last_request_at, :only => :destroy

  private

  def min_last_request_at
    current_user.update_attribute(:last_request_at, Time.at(0))
  end
    
end
