require "application_system_test_case"

class MessagesTest < ApplicationSystemTestCase
  test "renders a page-worth of Message records sorted from most recent to least recent" do
    using_page_size 20 do |page_size|
      messages = Message.most_recent_first

      visit messages_path

      assert_messages messages.limit(page_size)
    end
  end

  test "renders a page-worth of Message records with an offset" do
    using_page_size 20 do |page_size|
      messages = Message.most_recent_first

      visit messages_path(page: 2)

      assert_messages messages.offset(page_size).limit(page_size)
    end
  end

  test "appends the next page-worth of Message records" do
    using_page_size 20 do |page_size|
      messages = Message.most_recent_first

      visit messages_path
      click_on("Next page") { _1["rel"] == "next" }

      assert_messages messages.limit(page_size * 2)
    end
  end

  test "prepends the previous page-worth of Message records" do
    using_page_size 20 do |page_size|
      messages = Message.most_recent_first

      visit messages_path(page: 2)
      click_on("Previous page") { _1["rel"] == "prev" }

      assert_messages messages.limit(page_size * 2)
    end
  end

  test "navigates page from links in Article content" do
    using_page_size 20 do |page_size|
      messages = Message.most_recent_first
      author = messages.pick(:author)

      visit messages_path(page: 2)
      click_on author, match: :first

      assert_no_link "Previous page"
      assert_messages messages.limit(page_size)
      assert_link "Next page", count: 1
    end
  end

  test "navigates in both directions" do
    using_page_size 20 do |page_size|
      messages = Message.most_recent_first

      visit messages_path(page: 3)
      click_link "Previous page", href: messages_path(page: 2)
      click_link "Previous page", href: messages_path(page: 1)
      click_link "Next page"

      assert_link "Previous page", count: 0
      assert_messages messages.limit(page_size * 4)
      assert_link "Next page", count: 1
    end
  end

  def assert_messages(messages)
    assert_css "article", count: messages.size
    messages.each_with_index do |message, index|
      assert_message message, index: index
    end
  end

  def assert_message(message, index:)
    assert_text message.content.to_plain_text, count: 1

    within "article:nth-of-type(#{index + 1})" do
      assert_text message.content.to_plain_text
    end
  end

  def using_page_size(size = Pagy::DEFAULT[:items], &block)
    original_size, Pagy::DEFAULT[:items] = Pagy::DEFAULT[:items], size

    block.call(size)
  ensure
    Pagy::DEFAULT[:items] = original_size
  end
end
