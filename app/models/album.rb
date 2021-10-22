class Album < ApplicationRecord
  has_many_attached :photos

  with_options presence: true do
    validates :name
  end
end
