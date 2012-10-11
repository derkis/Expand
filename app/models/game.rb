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

require 'expand_serialize'

class Game < ActiveRecord::Base

  # MIXINS
  include ExpandSerialize

  # ACTIVE RECORD CALLBACKS
  before_validation :set_default_status, :on => :create
  after_commit :set_proposing_player, :on => :create
  before_update :before_update_handler
  
  # CONSTANTS
  PROPOSED = 0; STARTED = 1; FINISHED = 2
  
  # ASSOSCIATIONS
  has_many :players, :dependent => :destroy
  has_many :users, :through => :players
  has_many :turns, :dependent => :destroy
  belongs_to :template

  # ACCESSORS
  attr_accessible :players, :players_attributes, :status, :proposing_player, :template, :turn_id
  accepts_nested_attributes_for :players, :allow_destroy => true

  # VALIDATIONS
  validates :status, :numericality => :true, :inclusion => { :in => [ PROPOSED, STARTED, FINISHED ] }
  validate :validate_number_of_players
  
  def validate_number_of_players
    self.errors.add(:base, 'Game must have at least 2 players') if self.players.reject(&:marked_for_destruction?).length < 2
  end
     
  # METHODS
  def current_turn
    Turn.find(self.turn_id)
  end

  def current_turn=(turn)
    self.update_attributes(:turn_id => turn.id)
  end

  def current_player_index
    current_turn.player.index
  end

  def debug_mode
    self.players.each do |p|
      return true if p.user_id == 1
    end

    return false
  end

  def set_default_status
    self.status ||= PROPOSED
  end
  
  def cur_data(current_user)
    datasan = self.current_turn.data_object
    datasan[player_index_for(current_user).to_s]
  end

  def last_action()
    if self.current_turn.action != nil
      return ActiveSupport::JSON.decode(self.current_turn.action)
    end
    return nil
  end

  def next_turn
    nextPlayerIX = (self.current_turn.player.index + 1) % self.players.count

    turn = current_turn.clone_next_turn

    # Update ourself to the next turn
    self.update_attributes(:turn_id => turn.id)

    # Update the new current_turn to the latest player id
    self.current_turn.update_attributes(:player_id => self.players.find_by_index(nextPlayerIX).id)
    turn
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
    # Assign player indexes
    self.players.each_with_index do |p, i|
      p.index = i
    end

    self.status ||= STARTED
    self.template_id ||= 1
    self.template.save
    self.save
    self.turn_id ||= Turn.create_first_turn_for(self, random_player_id).id
    self.save
  end

  def board_area
    template.height * template.width
  end

  def piece_index(row, column)
    row * template.width + column
  end

  def random_player_id
    self.players.shuffle.first.id
  end

  def valid_action(current_user)
    if current_turn.is_starting_company
      return :code => Turn::Type[:start_company][:code] if current_user.id == current_turn.player.user.id || debug_mode
      return :code => Turn::Type[:no_action][:code]
    end

    return :code => Turn::Type[:place_piece][:code] if current_user.id == current_turn.player.user.id || debug_mode
    return :code => Turn::Type[:no_action][:code]
  end

  def player_index_for(current_user)
    self.players.each_with_index do |player, index|
      return index if player.user_id == current_user.id
    end
  end

  def board_array
    linear_index = 0
    Array.new(self.template.height){ Array.new }.each do |row_array|
      self.template.width.times do |column|
        row_array[column] = self.current_turn.board[linear_index]
        linear_index += 1
      end
    end
  end

end
