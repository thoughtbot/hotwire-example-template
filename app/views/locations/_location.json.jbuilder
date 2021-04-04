json.type "Feature"
json.geometry do
  json.type "Point"
  json.coordinates location.values_at(:longitude, :latitude)
end
json.properties do
  json.icon do
    json.id dom_id(location, :marker)
  end
end
