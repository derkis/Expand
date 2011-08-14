class UsersController < ApplicationController
  
  def show
    @user = User.find(params[:id])
    @title = @user.name
  end
  
  def new
    @title = 'Register'
  end
  
  def create
    @user = User.new(params[:user])
    if @user.save
      redirect_to "" # TODO redirect to lobby
    else
      @title = "Register"
      render 'new'
    end
  end
end
