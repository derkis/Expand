# == Schema Information
#
# Table name: users
#
#  id                 :integer         not null, primary key
#  name               :string(255)
#  email              :string(255)
#  encrypted_password :string(255)
#  salt               :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#  is_online          :boolean
#

class User < ActiveRecord::Base
  attr_accessor :password, :is_online
  attr_accessible :name, :email, :password, :password_confirmation
  
  has_one :player
  has_one :game, :through => :player

  email_regex = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
    
  validates :name,     :presence     => true,
                       :length       => { :maximum => 50 }
  validates :email,    :presence     => true,
                       :format       => { :with => email_regex },
                       :uniqueness   => { :case_sensitive => false }
  validates :password, :presence     => true,
                       :confirmation => true,
                       :length       => { :within => 6..40 }
                       
  before_save :encrypt_password

  class << self
    def authenticate(email, submitted_password)
      user = find_by_email(email)
      user if user and user.has_password?(submitted_password)
    end
  
    def authenticate_with_salt(id, cookie_salt)
      user = find_by_id(id)
      user if user and user.salt == cookie_salt
    end
  end
  
  def has_password?(submitted_password)
    encrypted_password == encrypt(submitted_password)
  end
  
  private
    def encrypt_password
      self.salt = make_salt if new_record?
      self.encrypted_password = encrypt(password)
    end
    
    def encrypt(string)
      secure_hash("#{salt}--#{string}")
    end
    
    def make_salt
      secure_hash("#{Time.now.utc}--#{password}")
    end
    
    def secure_hash(string)
      Digest::SHA2.hexdigest(string)
    end
end
