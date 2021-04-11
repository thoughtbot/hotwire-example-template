class Message < ApplicationRecord
  has_rich_text :content

  def mentioned_users
    content.body.attachables.select { |attachable| attachable.is_a? User }
  end
end
