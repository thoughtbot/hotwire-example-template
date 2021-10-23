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

  test "should preserve file attachments through an invalid submission" do
    visit new_album_url
    fill_in "Name", with: ""
    attach_file "Photos", file_fixture("photo.png")
    click_on "Create Album"

    assert_text "1 error prohibited this album from being saved"

    fill_in "Name", with: @album.name
    click_on "Create Album"

    assert_text "Album was successfully created"
    assert_text @album.name
    assert_link alt: "photo.png", count: 1
  end

  test "should update Album" do
    @album.photos.attach io: file_fixture("photo.png").open, filename: "photo.png"

    visit album_url(@album)
    click_on "Edit this album"

    fill_in "Name", with: @album.name
    attach_file "Photos", 2.times.map { file_fixture("photo.png") }
    click_on "Update Album"

    assert_text "Album was successfully updated"
    assert_text @album.name
    assert_link alt: "photo.png", count: 3
  end

  test "can update Album to have no photos" do
    @album.photos.attach io: file_fixture("photo.png").open, filename: "photo.png"

    visit album_url(@album)
    click_on "Edit this album"
    uncheck "photo.png"
    click_on "Update Album"

    assert_text "Album was successfully updated"
    assert_text @album.name
    assert_link alt: "photo.png", count: 0
  end

  test "can update Album by uploading and discarding" do
    @album.photos.attach io: file_fixture("photo.png").open, filename: "photo.png"

    visit edit_album_url(@album)
    uncheck "photo.png"
    attach_file "Photos", 2.times.map { file_fixture("photo.png") }
    click_on "Update Album"

    assert_text "Album was successfully updated"
    assert_link alt: "photo.png", count: 2
  end

  test "should destroy Album" do
    visit albums_url
    click_on "Show this album", match: :first
    click_on "Destroy", match: :first

    assert_text "Album was successfully destroyed"
  end
end
