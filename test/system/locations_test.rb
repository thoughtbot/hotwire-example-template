require "application_system_test_case"

class LocationsTest < ApplicationSystemTestCase
  setup do
    @location = locations(:union_square)
  end

  test "visiting the index" do
    visit locations_url
    assert_selector "h1", text: "Location"
  end

  test "should create Location" do
    visit locations_url
    click_on "New location"

    fill_in "Latitude", with: @location.latitude
    fill_in "Longitude", with: @location.longitude
    fill_in "Name", with: @location.name
    click_on "Create Location"

    assert_text "Location was successfully created"
    click_on "Back"
  end

  test "should update Location" do
    visit locations_url
    click_on "Show this location", match: :first
    click_on "Edit this location"

    fill_in "Latitude", with: @location.latitude
    fill_in "Longitude", with: @location.longitude
    fill_in "Name", with: @location.name
    click_on "Update Location"

    assert_text "Location was successfully updated"
    click_on "Back"
  end

  test "should destroy Location" do
    visit locations_url
    click_on "Show this location", match: :first
    click_on "Destroy this location"

    assert_text "Location was successfully destroyed"
  end

  test "list includes locations" do
    parks_on_broadway = locations(:union_square, :madison_square, :herald_square, :time_square, :columbus_circle)

    visit locations_path

    within_section "Locations" do
      parks_on_broadway.all? { assert_text _1.name }
    end
  end

  test "limits results geographically by bounding box" do
    parks_within_bounds = locations(:madison_square, :herald_square)
    parks_outside_bounds = locations(:union_square, :time_square, :columbus_circle)
    bbox = BoundingBox.containing(parks_within_bounds)

    visit locations_path
    fill_in("Bbox", with: bbox).then { click_on "Search this area" }

    within_section "Locations" do
      parks_within_bounds.all? { assert_text _1.name }
      parks_outside_bounds.none? { assert_no_text _1.name }
    end
  end
end
