# == Schema Information
#
# Table name: users
#
#  id                     :integer         not null, primary key
#  email                  :string(255)     default(""), not null
#  encrypted_password     :string(255)     default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer         default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  created_at             :datetime        not null
#  updated_at             :datetime        not null
#  last_request_at        :datetime
#

class User < ActiveRecord::Base
  
  # ACTIVE RECORD CALLBACKS
  before_create :set_create_defaults

  # RELATIONSHIPS
  has_many :players
  has_many :games, :through => :players
  
  # DEVISE OPTIONS
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, 
    :trackable, :validatable, :timeoutable

  # PUBLIC PROPERTIES
  attr_accessible :email, :password, :password_confirmation, :remember_me
  
  def set_create_defaults
    self.last_request_at ||= Time.now
  end

  def can_create_game?
    ActiveRecord::Base.connection.execute(
      "SELECT g.id AS game_id 
        FROM games g, players p 
        WHERE g.id = p.game_id AND g.proposing_player = p.id 
          AND g.status = #{Game::State::Proposed} AND p.user_id = #{self.id}"
    ).empty?
  end
  
  def can_view_game?(game_id)
    !Player.includes([:game]).first(
      :conditions => ['game_id = ? AND user_id = ?', game_id, self.id]
    ).nil?
  end
  
end