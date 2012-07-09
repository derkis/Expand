# == Schema Information
#
# Table name: games
#
#  id                  :integer         not null, primary key
#  created_at          :datetime        not null
#  updated_at          :datetime        not null
#  status              :integer
#  board               :string(255)
#  game_description_id :integer
#

class Game < ActiveRecord::Base
  
  after_create :create_defaults
  before_update :start_game_defaults
  
  PROPOSED = 0; STARTED = 1; FINISHED = 2
  
  has_many :players, :dependent => :destroy
  has_many :users, :through => :players
  belongs_to :game_description

  attr_accessible :players, :players_attributes, :status, :game_description
  accepts_nested_attributes_for :players, :allow_destroy => true
  
  validates :status, :numericality => :true, :inclusion => { :in => [ PROPOSED, STARTED, FINISHED ] }
 
  def create_defaults
    self.status ||= PROPOSED
  end
  
  def start_game_defaults
    if(self.status_was == PROPOSED and self.status == STARTED and !self.game_description_id)
      start
    end
  end
  
  def start
    # Ensure status is indeed started
    self.status ||= STARTED
    # Make sure we have assigned ourselves a game description
    self.game_description_id ||= 1
    # Now load said description by id
    self.game_description = GameDescription.find(game_description_id)
    # Setup the board as all empty
    self.board = "e" * (self.game_description.height * self.game_description.width)
  end

  # queries
  def self.get_proposed_games_for(current_user)
    players_array = Player.includes([:game]).all(:conditions => ['user_id = ? AND games.status = ?', current_user.id, Game::PROPOSED])
    games_string = players_array.inject(' AND ') { |string, player| string += "p.game_id = #{player.game_id} OR " }
    players_array = ActiveRecord::Base.connection.execute(
      'SELECT DISTINCT p.id AS player_id, p.game_id AS game_id, u.email AS email FROM users u, players p WHERE u.id = p.user_id' + games_string[0..-5]
    );

    players_array.size.times do |i|
      players_array[i] = players_array[i].delete_if { |key, value| key.kind_of? Integer } 
    end
    players_array.group_by { |player| player["game_id"] }
  end
  
end
