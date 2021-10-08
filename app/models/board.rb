class Board < ApplicationRecord
  has_many :stages
  has_many :cards, through: :stages
end
