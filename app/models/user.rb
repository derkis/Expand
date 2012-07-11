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
  
  before_create :create_defaults
  
  has_many :players
  has_many :games, :through => :players
  
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, 
    :trackable, :validatable, :timeoutable

  attr_accessible :email, :password, :password_confirmation, :remember_me
  
  def create_defaults
    self.last_request_at ||= Time.now
  end
  
  # convenience methods
  def can_create_game?
    ActiveRecord::Base.connection.execute(
      "SELECT g.id AS game_id FROM games g, players p 
        WHERE g.id = p.game_id AND g.proposing_player = p.id AND g.status = #{Game::PROPOSED} AND p.user_id = #{self.id}"
    ).empty?
  end
  
  # queries
  def get_other_users_since(time)
    User.all(:conditions => [ "last_request_at > ? AND NOT email = ?", time, self.email ], :order => :id)
  end
  
end