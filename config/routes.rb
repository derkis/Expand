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
    end
  end

  resources :players, :only => :update

  match 'test' => 'games#new_game_test', :as => :new_game_test, :via => :get  
  match 'poll_game_state' => 'games#poll_game_state', :as => :poll_game_state, :via => :get

end
