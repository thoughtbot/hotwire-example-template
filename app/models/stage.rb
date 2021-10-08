class Stage < ApplicationRecord
  include RankedModel

  belongs_to :board

  has_many :cards

  ranks :column_order, with_same: :board_id
end
