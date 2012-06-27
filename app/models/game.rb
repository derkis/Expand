# == Schema Information
#
# Table name: games
#
#  id         :integer         not null, primary key
#  created_at :datetime        not null
#  updated_at :datetime        not null
#  status     :integer
#  board      :string(255)
#  width      :integer
#  height     :integer
#

class Game < ActiveRecord::Base
  after_initialize :init
  
  PROPOSED = 0; STARTED = 1; FINISHED = 2
  
  has_many :players, :dependent => :destroy
  has_many :users, :through => :players
  
  attr_accessible :players, :players_attributes, :status
  accepts_nested_attributes_for :players, :allow_destroy => true
  
  validates :status, :numericality => :true, :inclusion => { :in => [ PROPOSED, STARTED, FINISHED ] }
 
  def init
    self.status ||= PROPOSED
    self.width = 12
    self.height = 9
    self.board ="111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111"
  end  

end
