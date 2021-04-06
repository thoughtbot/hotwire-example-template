require "application_system_test_case"

class MessagesTest < ApplicationSystemTestCase
  setup do
    @message = messages(:alice_to_bob)
  end

  test "visiting the index" do
    visit messages_url
    assert_selector "h1", text: "Message"
  end

  test "should create Message" do
    visit messages_url
    click_on "New message"

    click_on "Create Message"

    assert_text "Message was successfully created"
    click_on "Back"
  end

  test "should update Message" do
    visit messages_url
    click_on "Show this message", match: :first
    click_on "Edit this message"

    click_on "Update Message"

    assert_text "Message was successfully updated"
    click_on "Back"
  end

  test "should destroy Message" do
    visit messages_url
    click_on "Show this message", match: :first
    click_on "Destroy this message"

    assert_text "Message was successfully destroyed"
  end

  test "transforms a mention as a link to the User" do
    alice = users(:alice)

    visit(messages_path).then { click_on "New message" }; sleep 1
    fill_in_rich_text_area("Content", with: "Hello @alice")

    click_on("Create Message").then { assert_text "Message was successfully created." }

    click_link(alice.username).then { assert_text alice.name }
  end
end
