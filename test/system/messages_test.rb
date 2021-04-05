require "application_system_test_case"

class MessagesTest < ApplicationSystemTestCase
  setup do
    @message = messages(:one)
  end

  test "visiting the index" do
    visit messages_url
    assert_selector "h1", text: "Message"
  end

  test "creating a Message" do
    visit messages_url
    click_on "New message"

    fill_in "Body", with: @message.body
    click_on "Create Message"

    assert_text "Message was successfully created"
    click_on "Back"
  end

  test "updating a Message" do
    visit messages_url
    click_on "Show this message", match: :first
    click_on "Edit this message"

    fill_in "Body", with: @message.body
    click_on "Update Message"

    assert_text "Message was successfully updated"
    click_on "Back"
  end

  test "destroying a Message" do
    visit messages_url
    click_on "Show this message", match: :first
    click_on "Destroy"

    assert_text "Message was successfully destroyed"
  end
end
