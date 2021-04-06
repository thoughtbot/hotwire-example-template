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

  test "searches for Messages based on their body content, without changing the current page" do
    monday, last_monday, two_mondays_ago = messages(:from_0_days_ago, :from_7_days_ago, :from_14_days_ago)
    yesterday, last_sunday = messages(:from_1_days_ago, :from_8_days_ago)

    visit messages_path
    fill_in "Query", with: "Monday"

    within_section "Results" do
      assert_text monday.body
      assert_text last_monday.body
      assert_text two_mondays_ago.body
      assert_no_text yesterday.body
      assert_no_text last_sunday.body
    end
    within_section "Message" do
      assert_text monday.body
      assert_text last_monday.body
      assert_text two_mondays_ago.body
      assert_text yesterday.body
      assert_text last_sunday.body
    end
  end

  test "limits the visibility of the Search Results based on the field's state" do
    visit(messages_path)

    assert_no_selector :section, "Results"

    fill_in "Query", with: "Today"

    assert_selector :section, "Results"

    fill_in "Query", with: "   "

    within_section("Results") { assert_no_link }
  end

  test "navigates the results as a combobox" do
    monday, last_monday, two_mondays_ago = messages(:from_0_days_ago, :from_7_days_ago, :from_14_days_ago)

    visit messages_path
    fill_in "Query", with: "Monday"
    within_section "Results" do
      send_keys(:arrow_down).then { assert_list_box_option monday.body, selected: true }
      send_keys(:arrow_down).then { assert_list_box_option last_monday.body, selected: true }
      send_keys(:arrow_down).then { assert_list_box_option two_mondays_ago.body, selected: true }
    end
    send_keys :enter

    assert_link "Edit this message", href: edit_message_path(two_mondays_ago)
  end

  def assert_list_box_option(locator, selected: nil, **options)
    assert_selector :list_box_option, locator, **options do |listbox|
      selected.nil? || listbox["aria-selected"] == selected.to_s
    end
  end
end
