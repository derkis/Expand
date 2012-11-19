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
    Proposed = 0; Ready = 1; Starting = 2; Started = 3; Finished = 4; Canceled = 5

    def self.all
      return [ Proposed, Ready, Starting, Started, Finished, Canceled ]
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
  
  def finish
    update_attributes(:status => State::Finished)
  end
  
  def cur_data(current_user)
    datasan = self.cur_turn.data_hash

    if !debug_mode
      # Here we sanitize the game data so the current_user cannot see the other player data
      datasan["players"].each_with_index do |p, i|
        datasan["players"][i].clear() if i != player_index_for(current_user)
      end
    end

    datasan
  end

  def last_action
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
      return p.index if p.user_id == user.id
    end
  end

  def player_by_index(player_index)
    self.players.each do |p|
      return p if p.index == player_index
    end
  end

  def set_proposing_player
    player = self.players.object_passing_test do |player|
      self.proposing_player == player.user_id
    end
    self.update_attributes(:proposing_player => player.id)
    player.update_attributes(:accepted => true)
  end
    
  # GAME STATE MANAGEMENT
  def start_game_if_necessary
    start if self.status == State::Starting
  end

  def start
    self.players.each_with_index do |player, index|
      player.index = index
    end

    self.status = State::Started
    self.template_id ||= 1
    self.save

    self.turn_id ||= Turn.create_first_turn_for(self, random_player_id).id
    self.save
  end

  def advance_turn
    if cur_turn.data_hash["ending_game"] == true
        end_game
    else
      next_player_index = (self.cur_turn.player.index + 1) % self.players.count
      next_player = self.players.find_by_index(next_player_index)
      self.cur_turn = self.cur_turn.create_next_turn_with_player(next_player)
    end
  end

  def advance_turn_step
    self.cur_turn = self.cur_turn.create_next_turn_step()
  end

  # PLAYER LIST METHODS
  def remove_player(player)
    if players.count <= 2
      self.update_attributes!(:status => State::Canceled)
    else
      binding.pry
      player.update_attributes!(:game_id => nil)
    end
  end

  # callback from a player object when its state is initally set to true
  def player_did_accept
    game_is_ready = self.players.inject(true) do |is_ready, player| 
      is_ready and player.accepted
    end
    if game_is_ready then self.update_attributes(:status => State::Ready) end 
  end

  # SETTERS & GETTERS
  def cur_turn
    Turn.find(self.turn_id)
  end

  def cur_turn=(turn)
    self.update_attributes(:turn_id => turn.id)
  end

  def pass_through(object)
    object
  end

  def board
    cur_turn.board
  end

  def cur_turn_number
    cur_turn.number
  end

  def cur_player
    { :index => cur_player_index }
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

  def board_array
    linear_index = 0
    Array.new(self.template.height){ Array.new }.each do |row_array|
      self.template.width.times do |column|
        row_array[column] = self.cur_turn.board[linear_index]
        linear_index += 1
      end
    end
  end

  # --------------------------------------------------
  # A game is endable when:
  #
  # * A company has more than 41 tiles
  # * All established companies have more than 11 tiles
  #
  # Note this function MUST be called AFTER the company
  # sizes have been updated.
  # --------------------------------------------------
  def can_end_game()
    return false if cur_turn.num_established_companies == 0

    max_company_size = 0
    min_company_size = 1000

    cur_turn.data_hash["companies"].each do |c_a, company|
      if company["size"] > 0
        max_company_size = company["size"].to_i if company["size"].to_i > max_company_size
        min_company_size = company["size"].to_i if company["size"].to_i < min_company_size
      end
    end

    return true if max_company_size >= 41 || min_company_size > 10
    return false
  end

  # --------------------------------------------------
  # Ends the game, calculating all relevant majority / minorities
  # and assigning the rank of players and updating the notifications
  #
  # Note: this function does not actually do any checks to see
  # whether the game is legally endable, it just ends the game as is
  # --------------------------------------------------  
  def end_game()
    data_hash = cur_turn.data_hash
    
    return if data_hash.has_key? "game_over"

    data_hash["game_over"] = true

    Engine.add_notification(self, data_hash, "GAME HAS ENDED!", false)

    # Award all majority / minorities to every player for ONLY established companies
    # (obviously some player may have a stock at this point in a company that is not
    # established)
    data_hash["companies"].each do |c_a, company|
      if company["size"] > 0
        Engine.award_majority_minority(self, data_hash, c_a)

        # Now sell every player's stock in every company
        data_hash["players"].each_with_index do |player, i|
          stock = (player["stock_count"].has_key?(c_a) && player["stock_count"][c_a].to_i > 0) ? player["stock_count"][c_a] : 0
          if stock > 0
            Engine.add_notification(self, data_hash, player_by_index(player["index"].to_i).user.email + " sells " + stock.to_s + " in " + Engine.company_html(company) + ".", false)
            player["money"] += stock * cur_turn.stock_value_for(c_a)
            player["stock_count"][c_a] -= stock
            company["stock_count"] += stock
          end
        end
      end
    end

    Engine.add_notification(self, data_hash, "FINAL RESULTS:", false)

    # Sort all the players by their total assets
    players_ordered_by_money = data_hash["players"].dup
    players_ordered_by_money.sort! { |a,b| b["money"] <=> a["money"] }

    players_ordered_by_money.each_with_index do |p, i|
      Engine.add_notification(self, data_hash, (i + 1).to_s + ")" + player_by_index(p["index"].to_i).user.email + " $" + p["money"].to_s, false)
    end

    cur_turn.serialize_data_hash(data_hash)

    update_attributes(:status => State::Finished)
  end
end
