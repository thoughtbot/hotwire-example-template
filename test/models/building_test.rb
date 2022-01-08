require "test_helper"

class BuildingTest < ActiveSupport::TestCase
  test "validates the presence of line_1" do
    building = Building.new

    valid = building.validate

    assert_not valid
    assert_includes building.errors, :line_1
  end

  test "validates the presence of line_2" do
    building = Building.new

    valid = building.validate

    assert_not valid
    assert_includes building.errors, :line_2
  end

  test "validates the presence of city" do
    building = Building.new

    valid = building.validate

    assert_not valid
    assert_includes building.errors, :city
  end

  test "validates the presence of state" do
    building = Building.new country: "US"

    valid = building.validate

    assert_not valid
    assert_includes building.errors, :state
  end

  test "does not validates the presence of state for a country without states" do
    building = Building.new country: "VA"

    valid = building.validate

    assert_not valid
    assert_not_includes building.errors, :state
  end

  test "validates state is in the country" do
    building = Building.new state: "XX", country: "US"

    valid = building.validate

    assert_not valid
    assert_includes building.errors, :state
  end

  test "validates the presence of postal_code" do
    building = Building.new

    valid = building.validate

    assert_not valid
    assert_includes building.errors, :postal_code
  end

  test "does not validate the presence of management_phone_number when Owned" do
    building = Building.new building_type: "owned"

    valid = building.validate

    assert_not valid
    assert_not_includes building.errors, :management_phone_number
  end

  test "does not validate the presence of building_type_description when Owned" do
    building = Building.new building_type: "owned"

    valid = building.validate

    assert_not valid
    assert_not_includes building.errors, :building_type_description
  end

  test "validates the presence of management_phone_number when Leased" do
    building = Building.new building_type: "leased"

    valid = building.validate

    assert_not valid
    assert_includes building.errors, :management_phone_number
  end

  test "does not validate the presence of building_type_description when Leased" do
    building = Building.new building_type: "leased"

    valid = building.validate

    assert_not valid
    assert_not_includes building.errors, :building_type_description
  end

  test "validates the presence of management_phone_number when Other" do
    building = Building.new building_type: "other"

    valid = building.validate

    assert_not valid
    assert_includes building.errors, :building_type_description
  end

  test "does not validate the presence of management_phone_number when Other" do
    building = Building.new building_type: "other"

    valid = building.validate

    assert_not valid
    assert_not_includes building.errors, :management_phone_number
  end

  test "#state_name maps the state code to a name" do
    building = Building.new state: "NY"

    state_name = building.state_name

    assert_equal "New York", state_name
  end

  test "#country_name maps the country code to a name" do
    building = Building.new country: "US"

    country_name = building.country_name

    assert_equal "United States", country_name
  end
end
