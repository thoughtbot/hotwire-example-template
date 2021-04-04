json.type "Feature"
json.geometry do
  json.type "Point"
  json.coordinates location.values_at(:longitude, :latitude)
end
