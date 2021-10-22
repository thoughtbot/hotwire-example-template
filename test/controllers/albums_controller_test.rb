require "test_helper"

class AlbumsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @album = albums(:one)
  end

  test "should get index" do
    get albums_url
    assert_response :success
  end

  test "should get new" do
    get new_album_url
    assert_response :success
  end

  test "should create album" do
    assert_difference("Album.count") do
      post albums_url, params: { album: { name: @album.name } }
    end

    assert_redirected_to album_url(Album.last)
  end

  test "should create album with photos" do
    assert_difference -> { ActiveStorage::Attachment.count } => +2 do
      post albums_url, params: {
        album: { name: @album.name, photos: 2.times.map { fixture_file_upload("photo.png") } }
      }
    end

    assert_redirected_to album_url(Album.last)
  end

  test "should show album" do
    get album_url(@album)
    assert_response :success
  end

  test "should get edit" do
    get edit_album_url(@album)
    assert_response :success
  end

  test "should update album" do
    patch album_url(@album), params: { album: { name: @album.name } }
    assert_redirected_to album_url(@album)
  end

  test "should update album with photos" do
    assert_difference -> { @album.photos.count } => +2 do
      patch album_url(@album), params: {
        album: { photos: 2.times.map { fixture_file_upload("photo.png") } }
      }
    end

    assert_redirected_to album_url(@album)
  end

  test "should destroy album" do
    assert_difference("Album.count", -1) do
      delete album_url(@album)
    end

    assert_redirected_to albums_url
  end
end
