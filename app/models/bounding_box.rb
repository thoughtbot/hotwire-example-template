class BoundingBox
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :west, :decimal
  attribute :south, :decimal
  attribute :east, :decimal
  attribute :north, :decimal

  validates :west, :east, inclusion: { in: -180..180 }
  validates :south, :north, inclusion: { in: -90..90 }

  def self.parse(bbox)
    coordinates bbox.to_s.split(",")
  end

  def self.coordinates(coordinates)
    west, south, east, north = coordinates

    new west: west, south: south, east: east, north: north
  end

  def self.containing(locations)
    west, east = locations.pluck(:longitude).minmax
    south, north = locations.pluck(:latitude).minmax

    coordinates [ west, south, east, north ]
  end

  def to_h
    { longitude: west..east, latitude: south..north }
  end

  def to_a
    [ west, south, east, north ]
  end

  def to_s
    to_a.join(",")
  end
end
