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

    visit new_message_path
    fill_in_rich_text_area "Content", with: "Hello "
    fill_in("Username", with: "alice").then { click_on "Search" }
    within_fieldset("Mentions") { click_button alice.name }
    click_on("Create Message").then { assert_text "Message was successfully created." }

    click_link alice.name

    assert_text alice.username
    assert_text alice.name
  end

  test "renders the mentioned User's name while editing a Message" do
    alice_to_bob = messages(:alice_to_bob)
    bob = users(:bob)

    visit edit_message_path(alice_to_bob)

    within :rich_text_area, "Content" do
      assert_text alice_to_bob.content.to_plain_text
      assert_text bob.name
      assert_no_text bob.username
    end
  end

  test "renders a mention as a link to that User" do
    alice_to_bob = messages(:alice_to_bob)
    bob = users(:bob)

    visit message_path(alice_to_bob)
    click_link(bob.name).then { assert_text bob.name }

    assert_text bob.username
  end

  test "does not render a mention as a link when the User doesn't exist" do
    visit new_message_path
    fill_in_rich_text_area("Content", with: "Hello @xavier")
    click_on("Create Message").then { assert_text "Message was successfully created." }

    assert_no_link href: user_path("@xavier")
  end
end
