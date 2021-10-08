class Stage < ApplicationRecord
  include RankedModel

  belongs_to :board

  has_many :cards
  has_many :other_stages, ->(record) { without record },
    through: :board,
    source: :stages

  ranks :column_order, with_same: :board_id
end
