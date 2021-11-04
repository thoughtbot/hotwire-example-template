require "application_system_test_case"

class CustomersTest < ApplicationSystemTestCase
  test "renders all Customers" do
    alice, bob, chuck = customers :alice, :bob, :chuck

    visit customers_path

    within :table, "Customers" do
      assert_css "tr:nth-child(1)", text: alice.name
      assert_css "tr:nth-child(2)", text: bob.name
      assert_css "tr:nth-child(3)", text: chuck.name
    end
  end

  test "filters Customers by search query text" do
    alice, bob, chuck = customers :alice, :bob, :chuck

    visit customers_path
    within "nav" do
      fill_in "Search", with: "alice"
      click_on "Submit"
    end

    within :table, "Customers" do
      assert_css "tr", text: alice.name
      assert_no_css "tr", text: bob.name
      assert_no_css "tr", text: chuck.name
    end
  end

  test "filters Customers by their deactivation status" do
    alice, bob, chuck = customers :alice, :bob, :chuck

    visit customers_path
    within "aside" do
      check "Deactivated"
      click_on "Submit"
    end

    within :table, "Customers" do
      assert_no_css "tr", text: alice.name
      assert_no_css "tr", text: bob.name
      assert_css "tr", text: chuck.name
    end
  end

  test "filters Customers by when they made their first purchase" do
    travel_to "2021-11-04" do
      alice, bob, chuck = customers :alice, :bob, :chuck

      visit customers_path
      within "aside" do
        fill_in "First purchase before", with: "11-03-2021"
        click_on "Submit"
      end

      within :table, "Customers" do
        assert_css "tr:nth-of-type(1)", text: alice.name
        assert_css "tr:nth-of-type(2)", text: bob.name
        assert_no_css "tr", text: chuck.name
      end
    end
  end

  test "combines filters across forms" do
    travel_to "2021-11-04" do
      alice, bob, chuck = customers :alice, :bob, :chuck

      visit customers_path
      within "nav" do
        fill_in "Search", with: "alice"
        click_on "Submit"
      end
      within "aside" do
        fill_in "First purchase before", with: "11-03-2021"
        click_on "Submit"
      end

      within :table, "Customers" do
        assert_css "tr:nth-of-type(1)", text: alice.name
        assert_no_css "tr", text: bob.name
        assert_no_css "tr", text: chuck.name
      end
    end
  end
end
