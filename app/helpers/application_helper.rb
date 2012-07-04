module ApplicationHelper
  
  def set_last_request_at
    current_user.update_attribute(:last_request_at, Time.now) if user_signed_in?
  end
  
  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end
  
end
