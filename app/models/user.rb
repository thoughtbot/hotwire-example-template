class User < ApplicationRecord
  include ActionText::Attachable

  scope :username_matching_handle, ->(handle) { where <<~SQL, handle.delete_prefix("@") + "%" }
    username LIKE ?
  SQL

  def to_trix_content_attachment_partial_path
    "mentions/mention"
  end

  def to_attachable_partial_path
    "users/attachable"
  end
end
