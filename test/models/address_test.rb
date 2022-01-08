require "test_helper"

class AddressTest < ActiveSupport::TestCase
  test "validates the presence of line_1" do
    address = Address.new

    valid = address.validate

    assert_not valid
    assert_includes address.errors, :line_1
  end

  test "validates the presence of city" do
    address = Address.new

    valid = address.validate

    assert_not valid
    assert_includes address.errors, :city
  end

  test "validates the presence of state" do
    address = Address.new country: "US"

    valid = address.validate

    assert_not valid
    assert_includes address.errors, :state
  end

  test "does not validates the presence of state for a country without states" do
    address = Address.new country: "VA"

    valid = address.validate

    assert_not valid
    assert_not_includes address.errors, :state
  end

  test "validates state is in the country" do
    address = Address.new state: "XX", country: "US"

    valid = address.validate

    assert_not valid
    assert_includes address.errors, :state
  end

  test "validates the presence of postal_code" do
    address = Address.new

    valid = address.validate

    assert_not valid
    assert_includes address.errors, :postal_code
  end

  test "#state_name maps the state code to a name" do
    address = Address.new state: "NY"

    state_name = address.state_name

    assert_equal "New York", state_name
  end

  test "#country_name maps the country code to a name" do
    address = Address.new country: "US"

    country_name = address.country_name

    assert_equal "United States", country_name
  end
end
