Expand::Application.routes.draw do
  
  root :to => 'home#index'

  devise_for :users, :controllers => { :sessions => 'sessions' } do
    get 'users_online', :to => 'sessions#users_online', :as => :users_online
  end

  get 'portal' => 'games#index', :as => :portal
  resources :games, :except => :index do
    collection do
      get 'proposed'  => 'games#proposed_games',  :as => :proposed
      get 'ready'     => 'games#ready_games',     :as => :ready
      get 'started'   => 'games#started_games',   :as => :started
      # test routes -- remove from production
      get 'test'      => 'games#new_test_game',   :as => :test 
    end
  end

  resources :players, :only => :update

end
