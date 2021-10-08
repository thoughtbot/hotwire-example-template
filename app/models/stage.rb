class Stage < ApplicationRecord
  include RankedModel

  belongs_to :board

  ranks :column_order, with_same: :board_id
end
