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
  
  after_initialize :init
  
  PROPOSED = 0; STARTED = 1; FINISHED = 2
  
  has_many :players, :dependent => :destroy
  has_many :users, :through => :players
  belongs_to :game_description

  attr_accessible :players, :players_attributes, :status
  accepts_nested_attributes_for :players, :allow_destroy => true
  
  validates :status, :numericality => :true, :inclusion => { :in => [ PROPOSED, STARTED, FINISHED ] }
 
  def init
    self.status ||= PROPOSED
    # Set to default standard game description (12x9 with 25 count of stock cards, see seeds.rb)
    self.game_description_id ||= 1

    self.game_description = GameDescription.find(game_description_id)

    self.board = "e" * (self.game_description.height * self.game_description.width)
  end
end
