require "application_system_test_case"

class AlbumsTest < ApplicationSystemTestCase
  setup do
    @album = albums(:one)
  end

  test "visiting the index" do
    visit albums_url
    assert_selector "h1", text: "Albums"
  end

  test "should create Album" do
    visit albums_url
    click_on "New album"

    fill_in "Name", with: @album.name
    attach_file "Photos", 2.times.map { file_fixture("photo.png") }
    click_on "Create Album"

    assert_text "Album was successfully created"
    assert_text @album.name
    assert_link alt: "photo.png", count: 2
  end

  test "should update Album" do
    visit albums_url
    click_on "Show this album", match: :first
    click_on "Edit this album"

    fill_in "Name", with: @album.name
    click_on "Update Album"

    assert_text "Album was successfully updated"
    click_on "Back"
  end

  test "should destroy Album" do
    visit albums_url
    click_on "Show this album", match: :first
    click_on "Destroy", match: :first

    assert_text "Album was successfully destroyed"
  end
end
