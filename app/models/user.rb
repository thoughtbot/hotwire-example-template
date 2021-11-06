class User < ApplicationRecord
  has_one_attached :avatar

  with_options class_name: "Message" do
    has_many :sent_messages, foreign_key: :sender_id
  end
end
