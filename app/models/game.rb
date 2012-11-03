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

require 'expand_serializer'
require 'game_serialization'

class Game < ActiveRecord::Base

  # MIXINS
  include ExpandSerializer
  include GameSerialization

  # ACTIVE RECORD CALLBACKS
  before_validation :set_default_status, :on => :create
  after_commit :set_proposing_player, :on => :create
  after_update :start_game_if_necessary
  
  # CONSTANTS
  module State
    Proposed = 0; Starting = 1; Started = 2; Finished = 3

    def self.all
      return [ Proposed, Starting, Started, Finished ]
    end
  end

  # ASSOSCIATIONS
  has_many :players, :dependent => :destroy
  has_many :users, :through => :players
  has_many :turns, :dependent => :destroy
  belongs_to :template

  # ACCESSORS
  attr_accessible :players, :players_attributes, :status, :proposing_player, :template, :turn_id
  accepts_nested_attributes_for :players, :allow_destroy => true

  # VALIDATIONS
  validates :status, :numericality => :true, :inclusion => { :in => State.all }
  validate :validate_number_of_players

  # VALIDATORS  
  def validate_number_of_players
    self.errors.add(:base, 'Game must have at least 2 players') if self.players.reject(&:marked_for_destruction?).length < 2
  end

  # INITIALIZATION
  def set_default_status
    self.status ||= State::Proposed
  end
  
  def cur_data(current_user)
    datasan = self.cur_turn.data_hash

    # Here we sanitize the game data so the current_user cannot see the other player data
    datasan["players"].each_with_index do |p, i|
      datasan["players"][i].clear() if i != player_index_for(current_user)
    end

    datasan
  end

  def last_action()
    if self.cur_turn.action != nil
      return ActiveSupport::JSON.decode(self.cur_turn.action)
    end
    return nil
  end

  def next_turn
    nextPlayerIX = (self.cur_turn.player.index + 1) % self.players.count

    turn = cur_turn.clone_next_turn

    # Update ourself to the next turn
    self.update_attributes(:turn_id => turn.id)

    # Update the new cur_turn to the latest player id
    self.cur_turn.update_attributes(:player_id => self.players.find_by_index(nextPlayerIX).id)
    turn
  end

  def cur_player
    self.cur_turn.player
  end

  def cur_player_index
    self.cur_turn.player.index
  end

  def user_player_index(user)
    player_index_for(user)
  end

  def player_index_for(user)
    self.players.each do |p|
      return p.index if p.user_id = user.id
    end
  end

  def set_proposing_player
    player = self.players.object_passing_test do |player|
      self.proposing_player == player.user_id
    end
    self.proposing_player = player.id
    self.save
  end
    
  # GAME STATE MANAGEMENT
  def start_game_if_necessary
    start if self.status == State::Starting
  end

  def start
    self.players.each_with_index do |p, i|
      p.index = i
    end

    self.status = State::Started
    self.template_id ||= 1
    self.save

    self.turn_id ||= Turn.create_first_turn_for(self, random_player_id).id
    self.save
  end

  def advance_turn
    next_player_index = (self.cur_turn.player.index + 1) % self.players.count
    next_player = self.players.find_by_index(next_player_index)
    self.cur_turn = self.cur_turn.create_next_turn_with_player(next_player)
  end

  # SETTERS & GETTERS
  def cur_turn
    Turn.find(self.turn_id)
  end

  def cur_turn=(turn)
    self.update_attributes(:turn_id => turn.id)
  end

  def board
    cur_turn.board
  end

  def cur_turn_number
    cur_turn.number
  end

  def cur_player
    {:index => cur_player_index}
  end

  def index_for_player (player)

  end

  def valid_action(current_user)
    if cur_turn.is_starting_company
      return :code => Turn::START_COMPANY if current_user.id == cur_turn.player.user.id || debug_mode
      return :code => Turn::NONE
    end

    return :code => Turn::PLACE_PIECE if current_user.id == cur_turn.player.user.id || debug_mode
    return :code => Turn::NONE
  end

  def data_for_user(current_user)
    datasan = cur_turn.data_hash
    datasan[player_index_for(current_user).to_s]
  end

  def random_player_id
    self.players.shuffle.first.id
  end

  # NOT SURE WHAT TO DO ABOUT THIS ONE
  def board_array
    linear_index = 0
    Array.new(self.template.height){ Array.new }.each do |row_array|
      self.template.width.times do |column|
        row_array[column] = self.cur_turn.board[linear_index]
        linear_index += 1
      end
    end
  end

end
