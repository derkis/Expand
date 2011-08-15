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
    @user = User.new(params[:user])
    if @user.save
      sign_in @user
      flash[:success] = "Welcome"
      redirect_to "" # TODO redirect to lobby
    else
      @title = "Register"
      render 'new'
    end
  end
end
