class Team < ApplicationRecord
  has_many :draftings
  has_many :players, through: :draftings

  accepts_nested_attributes_for :draftings
end
