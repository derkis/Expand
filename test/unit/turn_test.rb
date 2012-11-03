# == Schema Information
#
# Table name: turns
#
#  id         :integer         not null, primary key
#  game_id    :integer
#  player_id  :integer
#  number     :integer
#  board      :string(255)
#  data       :text
#  action     :text
#  created_at :datetime        not null
#  updated_at :datetime        not null
#  step       :integer
#

require 'test_helper'

class TurnTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
