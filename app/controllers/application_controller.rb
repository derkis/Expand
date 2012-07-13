require 'application_helper'

class ApplicationController < ActionController::Base

  include ApplicationHelper
  
  protect_from_forgery()

  private
  # devise redirects
  def after_sign_in_path_for(resource_or_scope)
    :portal
  end

  def after_sign_out_path_for(resource_or_scope)
    :root
  end

end
