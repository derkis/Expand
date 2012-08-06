# == Schema Information
#
# Table name: games
#
#  id               :integer         not null, primary key
#  created_at       :datetime        not null
#  updated_at       :datetime        not null
#  status           :integer
#  template_id      :integer
#  proposing_player :integer
#  turn_id          :integer
#

# == Schema Information
#
# Table name: games
#
#  id               :integer         not null, primary key
#  created_at       :datetime        not null
#  updated_at       :datetime        not null
#  status           :integer
#  template_id      :integer
#  proposing_player :integer
#  turn_id          :integer
#
class Game < ActiveRecord::Base
  
  #####################################################
  # Callbacks
  #####################################################
  before_validation :set_default_status, :on => :create
  after_commit :set_proposing_player, :on => :create
  before_update :before_update_handler
  
  #####################################################
  # Constants
  #####################################################
  PROPOSED = 0; STARTED = 1; FINISHED = 2
  
  #####################################################
  # Associations
  #####################################################
  has_many :players, :dependent => :destroy
  has_many :users, :through => :players
  has_many :turns, :dependent => :destroy
  belongs_to :template

  #####################################################
  # Attribute Settings
  #####################################################
  attr_accessor :current_user
  attr_accessible :players, :players_attributes, :status, :proposing_player, :template
  accepts_nested_attributes_for :players, :allow_destroy => true
  
  #####################################################
  # Validation
  #####################################################
  validates :status, :numericality => :true, :inclusion => { :in => [ PROPOSED, STARTED, FINISHED ] }
  validate :validate_number_of_players
  
  #####################################################
  # Methods
  #####################################################
  def cur_turn
    turns.last
  end

  def debug_mode
    self.players.each do |p|
      return true if p.id == 1
    end

    return false
  end

  def validate_number_of_players
    self.errors.add(:base, 'Game must have at least 2 players') if self.players.reject(&:marked_for_destruction?).length < 2
  end
     
  def set_default_status
    self.status ||= PROPOSED
  end
  
  def set_proposing_player
    self.players.each do |player|
      if self.proposing_player == player.user_id
        self.proposing_player = player.id
        self.save
        break
      end
    end
  end
  
  def before_update_handler
    start if self.status_was == PROPOSED
  end
  
  def start
    self.status ||= STARTED
    self.template_id ||= 1
    self.template.save
    self.save
    self.turn_id ||= Turn.create_first_turn_for(self, random_player_id).id
  end

  def board_area
    template.height * template.width
  end

  def random_player_id
    self.players.shuffle.first.id
  end

  def current_user_valid_actions
    # If the player is not the current player, they cannot do anything
    if current_user.id == cur_turn.player.user.id
      return [:type => "PLACE_TILE"]
    end

    return [:type => "DEBUG"] if debug_mode
    return [:type => "NOT_YOUR_TURN"]
  end

  #####################################################
  # Queries
  #####################################################
  def self.get_proposed_games_for(current_user)
    players_array = Player.includes([:game]).all(:conditions => ['user_id = ? AND games.status = ?', current_user.id, Game::PROPOSED])
    games_string = players_array.inject(' AND (') { |string, player| string += "p.game_id = #{player.game_id} OR " }
    players_array = ActiveRecord::Base.connection.execute(
      'SELECT DISTINCT p.id AS player_id, p.game_id AS game_id, p.accepted AS accepted, u.email AS email 
        FROM users u, players p WHERE u.id = p.user_id' + ((games_string.length > 6) ? (games_string[0..-5]) + ')' : '')
    );

    players_array.size.times do |i|
      players_array[i] = players_array[i].delete_if { |key, value| key.kind_of? Integer } 
    end
    players_array.group_by { |player| player['game_id'] }
  end

  def self.get_ready_game_for(current_user)
    game = Game.includes([:players]).first(:conditions =>
      ['game_id = players.game_id AND proposing_player = players.id AND status = ? AND players.user_id = ?', 
        Game::PROPOSED, current_user.id]
    )
    return nil unless game

    players_are_ready = game.players.inject(true) { |is_ready, player| is_ready &&= player.accepted }
    other_player_emails = User.includes([:players]).all(:select => :email, :conditions =>
      ['user_id = players.user_id AND players.game_id = ? AND NOT user_id = ?', game.id, current_user.id]
    ).map(&:email)
    { :game_id => game.id, :other_players => other_player_emails } if players_are_ready
  end

  def self.get_started_game_for(current_user)
    Game.includes([:players]).first(:select => :game_id, :conditions =>
      ['status = ? AND game_id = players.game_id AND players.user_id = ?', Game::STARTED, current_user.id]
    )
  end
end
