class Category < ApplicationRecord
  has_many :categorizations
  has_many :articles, through: :categorizations
end
