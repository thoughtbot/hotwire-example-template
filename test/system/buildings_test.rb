require "application_system_test_case"

class BuildingsTest < ApplicationSystemTestCase
  test "saves a valid Owned Building" do
    visit new_building_path
    within_section "New building" do
      choose("Owned", fieldset: "Describe the building")
      assert_no_field "Management phone number", type: "tel", fieldset: "Leased"
      within_fieldset "Address" do
        select "United States", from: "Country"
        fill_in "Line 1", with: "1384 Broadway"
        fill_in "Line 2", with: "Floor 20"
        fill_in "City", with: "New York"
        select "New York", from: "State"
        fill_in "Postal code", with: "10013"
      end
      click_on "Create Building"
    end

    within_section "1384 Broadway Floor 20 (Owned)" do
      assert_text "New York, New York 10013, United States"
    end
    assert_no_selector :alert
  end

  test "saves a valid Rented Building" do
    visit new_building_path
    within_section "New building" do
      assert_changes -> { page.has_field? "Management phone number", type: "tel", fieldset: "Leased" } do
        choose("Leased", fieldset: "Describe the building")
      end
      fill_in "Management phone number", with: "5555555555", fieldset: "Leased"
      within_fieldset "Address" do
        select "United States", from: "Country"
        fill_in "Line 1", with: "1384 Broadway"
        fill_in "Line 2", with: "Floor 20"
        fill_in "City", with: "New York"
        select "New York", from: "State"
        fill_in "Postal code", with: "10013"
      end
      click_on "Create Building"
    end

    within_section "1384 Broadway Floor 20 (Leased)" do
      assert_link "555-555-5555", href: "tel:5555555555"
      assert_text "New York, New York 10013, United States"
    end
    assert_no_selector :alert
  end

  test "saves a valid Other Building" do
    visit new_building_path
    within_section "New building" do
      assert_changes -> { page.has_field? "Description", fieldset: "Other" } do
        choose("Other", fieldset: "Describe the building")
      end
      fill_in "Description", with: "In escrow", fieldset: "Other"
      within_fieldset "Address" do
        select "United States", from: "Country"
        fill_in "Line 1", with: "1384 Broadway"
        fill_in "Line 2", with: "Floor 20"
        fill_in "City", with: "New York"
        select "New York", from: "State"
        fill_in "Postal code", with: "10013"
      end
      click_on "Create Building"
    end

    within_section "1384 Broadway Floor 20 (In escrow)" do
      assert_text "New York, New York 10013, United States"
    end
    assert_no_selector :alert
  end

  test "rejects an invalid Owned Building" do
    visit new_building_path
    within_section "New building" do
      choose "Owned", fieldset: "Describe the building"
      within_fieldset "Address" do
        select "United States", from: "Country"
        fill_in "Line 1", with: "1384 Broadway"
        fill_in "Line 2", with: "Floor 20"
      end
      click_on "Create Building"
    end

    assert_no_selector :section, "1384 Broadway Floor 20 (Owned)"
    assert_selector :alert, "City can't be blank"
  end

  test "rejects an invalid Rented Building" do
    visit new_building_path
    within_section "New building" do
      choose "Leased", fieldset: "Describe the building"
      within_fieldset "Address" do
        select "United States", from: "Country"
        fill_in "Line 1", with: "1384 Broadway"
        fill_in "Line 2", with: "Floor 20"
      end
      click_on "Create Building"
    end

    assert_no_selector :section, "1384 Broadway Floor 20 (Leased)"
    assert_selector :alert, "Management phone number can't be blank"
  end

  test "rejects an invalid Other Building" do
    visit new_building_path
    within_section "New building" do
      choose "Other", fieldset: "Describe the building"
      within_fieldset "Address" do
        select "United States", from: "Country"
        fill_in "Line 1", with: "1384 Broadway"
        fill_in "Line 2", with: "Floor 20"
      end
      click_on "Create Building"
    end

    assert_no_selector :section, "1384 Broadway Floor 20"
    assert_selector :alert, "Description can't be blank"
  end

  test "selecting a Country refreshs the State options" do
    visit new_building_path
    within_section "New building" do
      select("Vatican City", from: "Country").then { click_on "Select country" }
      assert_no_select "State"

      select("Canada", from: "Country").then { click_on "Select country" }
      assert_select "State", fieldset: "Address", selected: "Alberta"
    end
  end

  def within_section(*arguments, **options, &block)
    within(:section, *arguments, **options, &block)
  end

  def within_fieldset(*arguments, **options, &block)
    within(:fieldset, *arguments, **options, &block)
  end
end
