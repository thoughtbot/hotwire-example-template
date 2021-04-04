json.type "FeatureCollection"
json.features @locations, partial: "locations/location", as: :location
json.bbox @bounding_box.to_a
