class Message < ApplicationRecord
  has_rich_text :content

  with_options presence: true do
    validates :content
    validates :recipient
    validates :sender
  end
end
