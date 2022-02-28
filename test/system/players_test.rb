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

  test "Left Arrow: Moves focus one cell to the left." do
    first_player = players.first

    visit players_path
    send_keys(:tab)
    send_keys(:tab).then { assert_cell first_player.common_name, focused: true, column: "Name" }
    send_keys(:right)
    send_keys(:left).then { assert_cell first_player.common_name, focused: true, column: "Name" }
  end

  test "Down Arrow: Moves focus one cell down." do
    first_player, second_player, * = players

    visit players_path
    2.times { send_keys :tab }.then { assert_cell first_player.common_name, focused: true, column: "Name" }
    send_keys(:down).then { assert_cell second_player.common_name, focused: true, column: "Name" }
  end

  test "Up Arrow: Moves focus one cell down." do
    first_player = players.first

    visit players_path
    2.times { send_keys :tab }.then { assert_cell first_player.common_name, focused: true, column: "Name" }
    send_keys(:down)
    send_keys(:up).then { assert_cell first_player.common_name, focused: true, column: "Name" }
  end

  test "Home: moves focus to the first cell in the row that contains focus." do
    first_player = players.first

    visit players_path
    send_keys(:tab)
    send_keys(:tab).then { assert_cell focused: true, column: "Name" }
    send_keys(:right).then { assert_cell focused: true, column: "League" }
    send_keys(:right).then { assert_cell focused: true, column: "Hall of Fame" }
    send_keys(:home).then { assert_cell first_player.common_name, focused: true, column: "Name" }
  end

  test "End: moves focus to the last cell in the row that contains focus." do
    first_player = players.first

    visit players_path
    send_keys(:tab)
    send_keys(:tab).then { assert_cell first_player.common_name, focused: true, column: "Name" }
    send_keys(:end).then { assert_cell first_player.position, focused: true, column: "Batter or Pitcher" }
  end

  def assert_cell(...)
    assert_selector(:cell, ...)
  end
end
