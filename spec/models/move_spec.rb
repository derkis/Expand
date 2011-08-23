# == Schema Information
#
# Table name: moves
#
#  id         :integer         not null, primary key
#  type       :string(255)
#  contents   :string(255)
#  created_at :datetime
#  updated_at :datetime
#  game_id    :integer
#

require 'spec_helper'

describe Move do
  pending "add some examples to (or delete) #{__FILE__}"
end
