require "application_system_test_case"

class ArticlesTest < ApplicationSystemTestCase
  setup do
    @article = articles(:one)
  end

  test "visiting the index" do
    visit articles_url
    assert_selector "h1", text: "Article"
  end

  test "should create Article" do
    visit articles_url
    click_on "New article"

    fill_in "Content", with: @article.content
    click_on "Create Article"

    assert_text "Article was successfully created"
    click_on "Back"
  end

  test "should update Article" do
    visit articles_url
    click_on "Show this article", match: :first
    click_on "Edit this article"

    fill_in "Content", with: @article.content
    click_on "Update Article"

    assert_text "Article was successfully updated"
    click_on "Back"
  end

  test "should destroy Article" do
    visit articles_url
    click_on "Show this article", match: :first
    click_on "Destroy this article"

    assert_text "Article was successfully destroyed"
  end

  test "the new Article form provides a live-preview of how the text will be rendered" do
    visit new_article_path

    fill_in "Content", with: <<~TEXT
       Hello,


       World
    TEXT
    click_on "Preview Article"

    within "#article_preview" do
      assert_css "p", text: "Hello,"
      assert_css "p", text: "World"
    end

    click_on "Create Article"

    assert_text "Article was successfully created."
    assert_css "p", text: "Hello,"
    assert_css "p", text: "World"
  end
end
