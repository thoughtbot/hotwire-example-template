require "application_system_test_case"

class AddressesTest < ApplicationSystemTestCase
  test "saves a valid Address" do
    visit new_address_path
    within :section, "New address" do
      select "United States", from: "Country"
      fill_in "Line 1", with: "1384 Broadway"
      fill_in "Line 2", with: "Floor 20"
      fill_in "City", with: "New York"
      select "New York", from: "State"
      fill_in "Postal code", with: "10013"
      click_on "Create Address"
    end

    within :section, "1384 Broadway Floor 20" do
      assert_text "New York, New York 10013, United States"
    end
    assert_no_selector :alert
  end

  test "rejects an invalid Address" do
    visit new_address_path
    within :section, "New address" do
      fill_in "Line 1", with: "1384 Broadway"
      click_on "Create Address"
    end

    assert_selector :section, "New address"
    assert_selector :alert, "City can't be blank"
  end

  test "renders the estimated arrival time based on the country" do
    visit new_address_path

    select("United States", from: "Country").then { click_on "Select country" }

    assert_text "Estimated arrival: 8 months from now."

    select("Canada", from: "Country").then { click_on "Select country"}

    assert_text "Estimated arrival: about 1 month from now."

    select("Albania", from: "Country").then { click_on "Select country"}

    assert_text "Estimated arrival: 5 days from now."
  end

  test "selecting a Country refreshs the State options and preserves field values" do
    visit new_address_path
    within_section "New address" do
      fill_in "Line 1", with: "1384 Broadway"
      select("Vatican City", from: "Country").then { click_on "Select country" }
      assert_no_select "State"

      select("Canada", from: "Country").then { click_on "Select country" }
      assert_select "State", selected: "Alberta"
    end

    within :section, "New address" do
      assert_field "Line 1", with: "1384 Broadway"
    end
  end
end
