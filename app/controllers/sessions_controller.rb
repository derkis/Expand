class SessionsController < ApplicationController
  
  def new
    @title = 'Login'
  end
  
  def create
    user = User.authenticate(params[:session][:email], params[:session][:password])
    
    if user.nil?
      @title = "Login"
      flash.now[:error] = "Invalid email/password combination"
      render 'new'
    else
      sign_in user
      redirect_to :lobby
    end
  end
  
  def destroy
    sign_out
    redirect_to '/'
  end

end
