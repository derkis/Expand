class Game < ActiveRecord::Base
  has_many :players, :dependent => :destroy
  has_many :users, :through => :players
  
  attr_accessible :players, :players_attributes
  accepts_nested_attributes_for :players, :allow_destroy => true
end
