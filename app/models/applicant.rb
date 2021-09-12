class Applicant < ApplicationRecord
  has_many :references

  accepts_nested_attributes_for :references, allow_destroy: true

  validates_associated :references

  with_options presence: true do
    validates :name
    validates :references
  end
end
