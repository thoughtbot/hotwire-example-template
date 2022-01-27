class Article < ApplicationRecord
  has_many :categorizations
  has_many :categories, through: :categorizations

  has_rich_text :content

  with_options presence: true do
    validates :byline
    validates :content
    validates :name
  end
end
