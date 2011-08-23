# == Schema Information
#
# Table name: hotels
#
#  id         :integer         not null, primary key
#  stock      :integer
#  size       :integer
#  created_at :datetime
#  updated_at :datetime
#  name       :string(255)
#  quality    :string(255)
#  game_id    :integer
#

require 'spec_helper'

describe Hotel do
  pending "add some examples to (or delete) #{__FILE__}"
end
