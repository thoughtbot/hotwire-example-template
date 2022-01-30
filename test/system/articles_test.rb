require "application_system_test_case"

class ArticlesTest < ApplicationSystemTestCase
  test "show page renders the Article" do
    article = articles :hello_world
    hotwire, rails, stimulus, turbo = categories :hotwire, :rails, :stimulus, :turbo

    visit article_path(article)

    within_section article.name do
      assert_text localize(article.published_on, format: :long)
      assert_text hotwire.name
      assert_text rails.name
      assert_no_text stimulus.name
      assert_text turbo.name
      assert_text "By: #{article.byline}"
      assert_text article.content.to_plain_text
    end
  end

  test "edit page supports changing the Article" do
    article = articles :hello_world
    hotwire, rails, stimulus, turbo = categories :hotwire, :rails, :stimulus, :turbo

    travel_to "2022-01-01" do
      visit edit_article_path(article)
      fill_in "Name", with: "Goodbye, world"
      within :fieldset, "Categories" do
        uncheck hotwire.name
        uncheck rails.name
        check stimulus.name
        uncheck turbo.name
      end
      fill_in "Byline", with: "Anonymous"
      fill_in "Published on", with: "01/01/2022"
      fill_in_rich_text_area "Content", with: "Some changed content."
      click_on "Update Article"

      within_section "Goodbye, world" do
        assert_text "January 01, 2022"
        assert_no_text hotwire.name
        assert_no_text rails.name
        assert_text stimulus.name
        assert_no_text turbo.name
        assert_text "By: Anonymous"
        assert_text "Some changed content."
      end
    end
  end

  test "edit page rejects invalid Article submissions" do
    article = articles :hello_world
    hotwire, rails, stimulus, turbo = categories :hotwire, :rails, :stimulus, :turbo

    visit article_path(article)
    click_on "Edit Article"
    fill_in("Name", with: "").then                      { click_on "Update Article" }
    fill_in("Name", with: "A valid Article name").then  { click_on "Update Article" }

    within_section "A valid Article name" do
      assert_text localize(article.published_on, format: :long)
      assert_text hotwire.name
      assert_text rails.name
      assert_no_text stimulus.name
      assert_text turbo.name
      assert_text "By: #{article.byline}"
      assert_text article.content.to_plain_text
    end
  end

  test "supports inline editing the Name" do
    article = articles :hello_world

    visit article_path(article)
    within_section article.name do
      click_on("Edit Name").then { click_on "Cancel" }
      click_on("Edit Name").then { fill_in "Name", with: "" }
      click_on("Save Name").then { fill_in "Name", with: "Goodbye, world" }
      click_on "Save Name"
    end

    assert_selector :section, "Goodbye, world"
  end

  def within_section(*arguments, section_element: :section, **options, &block)
    within :section, *arguments, section_element:, **options, &block
  end
end
