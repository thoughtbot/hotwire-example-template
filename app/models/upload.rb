class Upload < ApplicationRecord
  has_one_attached :file

  after_touch -> { broadcast_replace }
end
