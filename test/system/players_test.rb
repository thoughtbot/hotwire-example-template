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

  test "Control + Home: moves focus to the first cell in the first row." do
    first_player, second_player, third_player = players.take(3)

    visit players_path
    2.times { send_keys :tab }.then { assert_cell focused: true, column: "Name" }
    send_keys(:down).then { assert_cell second_player.common_name, focused: true, column: "Name" }
    send_keys(:down).then { assert_cell third_player.common_name, focused: true, column: "Name" }
    send_keys(:end).then { assert_cell third_player.position, focused: true, column: "Batter or Pitcher" }
    send_keys([:control, :home]).then { assert_cell first_player.common_name, focused: true, column: "Name" }
  end

  test "Control + End: moves focus to the last cell in the last row." do
    last_player_on_page = players.take(Pagy::DEFAULT[:items]).last

    visit players_path
    2.times { send_keys :tab }.then { assert_cell focused: true, column: "Name" }
    send_keys([:control, :end]).then { assert_cell focused: true, column: "Batter or Pitcher" }
    send_keys(:home).then { assert_cell last_player_on_page.common_name, focused: true, column: "Name" }
  end

  test "Page Down: Moves focus down an author-determined number of rows" do
    eleventh_player = players.take(11).last

    visit players_path
    2.times { send_keys :tab }.then { assert_cell focused: true, column: "Name" }
    send_keys(:page_down).then { assert_cell eleventh_player.common_name, focused: true, column: "Name" }
  end

  test "Page Down: If focus is in the last row of the grid, focus does not move." do
    penultimate_player, ultimate_player = players.take(Pagy::DEFAULT[:items]).last(2)

    visit players_path
    2.times { send_keys :tab }.then { assert_cell focused: true, column: "Name" }
    5.times { send_keys :page_down }. then { assert_cell ultimate_player.common_name, focused: true, column: "Name"  }
    send_keys(:up). then { assert_cell penultimate_player.common_name, focused: true, column: "Name"  }
  end

  test "Page Up: Moves focus up an author-determined number of rows" do
    tenth_player = players.take(10).last
    ultimate_player = players.take(Pagy::DEFAULT[:items]).last

    visit players_path
    2.times { send_keys :tab }.then { assert_cell focused: true, column: "Name" }
    send_keys([:control, :end]).then { assert_cell ultimate_player.position, focused: true, column: "Batter or Pitcher" }
    send_keys(:home).then { assert_cell ultimate_player.common_name, focused: true, column: "Name" }
    send_keys(:page_up).then { assert_cell tenth_player.common_name, focused: true, column: "Name"  }
  end

  def assert_cell(...)
    assert_selector(:cell, ...)
  end
end
