class Location < ApplicationRecord
  scope :within, ->(bounding_box) { where bounding_box.to_h }
end
