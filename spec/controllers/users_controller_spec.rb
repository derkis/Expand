require 'spec_helper'

describe UsersController do
  render_views
  
  describe "GET 'new'" do
    it "should be successful" do
      get 'new'
      response.should be_success
    end
    
    it "should have the right title" do
      get :new
      response.should have_selector("title", :content => "Register")
    end
  end
  
  describe "POST 'create'" do
    
    describe "failure" do
      
      before(:each) do
        @attr = { :name => "", :email => "", :password => "", :password_confirmation => "" }
      end
      
      it "should not create a user" do
        lambda do
          post :create, :user => @attr
        end.should_not_change(User, :count)
      end
      
      it "should have the right title" do
        post :create, :user => @attr
        response.should have_selector(:title, :content => "Sign up")
      end
      
      it "should render a new page" do
        post :create, :user => @attr
        response.should render_template('new')
      end
    end
    
    describe "success" do
      
      before(:each) do
        @attr = { :name => "New User", :email => "user@example.com", :password => "foobar", :password_confirmation => "foobar" }
      end
      
      it "should create a user" do
        lambda do
          post :create, :user => @attr
        end.should change(User, :count).by(1)
      end
      
      it "should redirect the user to lobby page" do
        post :create, :user => @attr
        response.should redirect_to("") # TODO enter in url for lobby
      end
      
      it "should have a success messgae" do
        post :create, :user => @attr
        flash[:success].should =~ /Successfully registered/i
      end
    end
  end
end
