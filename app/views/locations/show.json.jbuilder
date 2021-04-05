json.type "FeatureCollection"
json.features [ @location ], partial: "locations/location", as: :location
json.bbox @bounding_box.to_a
