class UsersController < ApplicationController  
  def new
    @user = User.new
    @title = 'Register'
  end
  
  def show
    @user = User.find(params[:id])
    @title = @user.name
  end
  
  def create
    params[:user][:is_online] = false
    @user = User.new(params[:user])
    if @user.save
      sign_in @user
      flash[:success] = "Registered successfully, you may now begin playing!"
      redirect_to :lobby
    else
      @title = "Register"
      flash.now[:failure] = "Didn't work bro."
      render 'new'
    end
  end
end
