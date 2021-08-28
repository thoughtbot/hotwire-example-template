require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
  end

  test "visiting the index" do
    visit users_url
    assert_selector "h1", text: "User"
  end

  test "should create User" do
    visit users_url
    click_on "New user"

    fill_in "Name", with: @user.name
    fill_in "Username", with: @user.username
    click_on "Create User"

    assert_text "User was successfully created"
    click_on "Back"
  end

  test "should update User" do
    visit users_url
    click_on "Show this user", match: :first
    click_on "Edit this user"

    fill_in "Name", with: @user.name
    fill_in "Username", with: @user.username
    click_on "Update User"

    assert_text "User was successfully updated"
    click_on "Back"
  end

  test "should destroy User" do
    visit users_url
    click_on "Show this user", match: :first
    click_on "Destroy this user"

    assert_text "User was successfully destroyed"
  end
end
