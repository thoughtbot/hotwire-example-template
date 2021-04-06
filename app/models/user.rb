class User < ApplicationRecord
  include ActionText::Attachable

  scope :username_matching_handle, ->(handle) { where username: handle.delete_prefix("@") }

  def to_attachable_partial_path
    "users/attachable"
  end
end
