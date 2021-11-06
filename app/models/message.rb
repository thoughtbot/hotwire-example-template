class Message < ApplicationRecord
  has_rich_text :content

  with_options class_name: "User" do
    belongs_to :sender
    belongs_to :recipient
  end

  scope :latest_first, -> { order created_at: :desc }
  scope :involving, ->(users) { where sender: users, recipient: users }

  def broadcast_append_to_participants
    streamables = values_at(:sender, :recipient).sort

    broadcast_append_to streamables
  end
end
