class Message < ApplicationRecord
  has_rich_text :content

  scope :most_recent_first, -> { order created_at: :desc }
end
