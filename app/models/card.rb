class Card < ApplicationRecord
  belongs_to :stage

  has_rich_text :content
end
