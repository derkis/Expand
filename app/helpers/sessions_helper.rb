module SessionsHelper
  
  def current_user=(user)
    @current_user = user
  end
  
  def current_user
    @current_user ||= user_from_remember_token
  end
    
  def signed_in?
    !current_user.nil?
  end
  
  def sign_in(user)
    cookies.permanent.signed[:remember_token] = [user.id, user.salt]
    self.current_user = user
    self.current_user.toggle!(:is_online)
  end
  
  def sign_out
    self.current_user.toggle!(:is_online)
    cookies.delete(:remember_token)
    self.current_user = nil
  end
  
  def get_online_users
    online_users = User.find_all_by_is_online(true).reject! do |user|
      user.id == current_user.id
    end
  end
  
  private
    def user_from_remember_token
      remember_token = cookies.signed[:remember_token] || [nil, nil]
      User.authenticate_with_salt(*remember_token)
    end
end
