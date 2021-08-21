require "application_system_test_case"

class MessagesTest < ApplicationSystemTestCase
  test "create a new Message" do
    visit messages_path
    within(:section, "Messages") { click_on "New message" }
    within :section, "New message" do
      fill_in "From", with: "Alice"
      fill_in "To", with: "Bob"
      fill_in_rich_text_area "Content", with: "Hello, world"
      click_on "Send"
    end

    assert_no_selector :section, "New message"
    assert_text "Hello, world"
    assert_text "From: Alice"
    assert_text "To: Bob"
  end

  test "rejects invalid submissions" do
    visit messages_path
    within(:section, "Messages") { click_on "New message" }
    within :section, "New message" do
      fill_in "From", with: "Alice"
      click_on "Send"
    end

    within :section, "New message" do
      assert_selector :alert, "To can't be blank"
    end
  end
end
