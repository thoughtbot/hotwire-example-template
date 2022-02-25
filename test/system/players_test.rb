require "application_system_test_case"

class PlayersTest < ApplicationSystemTestCase
  test "only one of the focusable elements contained by the grid is included in the page tab sequence" do
    first_player = players.first

    visit players_path
    send_keys(:tab).then { assert_link "Next page", focused: true }
    send_keys(:tab).then { assert_cell first_player.common_name, focused: true, column: "Name" }
    send_keys(:tab).then { assert_link "Next page", focused: true }
    2.times { send_keys :shift, :tab }.then { assert_link "Next page", focused: true }
  end

  test "Right Arrow: Moves focus one cell to the right." do
    first_player = players.first

    visit players_path
    send_keys(:tab)
    send_keys(:tab).then { assert_cell first_player.common_name, focused: true, column: "Name" }
    send_keys(:right).then { assert_cell first_player.league, focused: true, column: "League" }
  end

  def assert_cell(...)
    assert_selector(:cell, ...)
  end
end
