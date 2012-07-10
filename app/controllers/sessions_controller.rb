require 'sessions_webservices'

class SessionsController < Devise::SessionsController
  
  include SessionsWebservices
  
end
