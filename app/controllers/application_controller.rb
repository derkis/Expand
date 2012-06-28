require 'application_helper'

class ApplicationController < ActionController::Base

  protect_from_forgery()
  
  def set_last_request_at
    current_user.update_attribute(:last_request_at, Time.now) if user_signed_in?
  end
  
  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end
  
  private
  # devise redirects
  def after_sign_in_path_for(resource_or_scope)
    :portal
  end
  
  def after_sign_out_path_for(resource_or_scope)
    :root
  end

end
