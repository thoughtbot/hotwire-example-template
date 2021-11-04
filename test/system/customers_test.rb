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
end
