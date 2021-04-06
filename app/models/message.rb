class Message < ApplicationRecord
  has_rich_text :content

  before_save do
    content.body = content.body.to_html.gsub(/\B\@(\w+)/) do |handle|
      if (user = User.username_matching_handle(handle).first)
        ActionText::Attachment.from_attachable(user).to_html
      else
        handle
      end
    end
  end
end
