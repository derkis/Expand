# == Schema Information
#
# Table name: players
#
#  id         :integer         not null, primary key
#  created_at :datetime        not null
#  updated_at :datetime        not null
#  game_id    :integer
#  user_id    :integer
#  accepted   :boolean
#

require 'test_helper'

class PlayerTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
