class Card < ApplicationRecord
  include RankedModel

  belongs_to :stage

  has_rich_text :content

  ranks :row_order, with_same: :stage_id
end
