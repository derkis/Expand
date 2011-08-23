# == Schema Information
#
# Table name: players
#
#  id         :integer         not null, primary key
#  created_at :datetime
#  updated_at :datetime
#  cash       :string(255)
#  stock      :string(255)
#  user_id    :integer
#  game_id    :integer
#

require 'spec_helper'

describe Player do
  pending "add some examples to (or delete) #{__FILE__}"
end
