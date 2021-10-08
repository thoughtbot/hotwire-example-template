require "application_system_test_case"

class BoardsTest < ApplicationSystemTestCase
  test "renders each Stage as a Section" do
    board = boards :tasks
    todo, doing, done = stages :todo, :doing, :done
    edit, write, setup = cards :edit, :write, :setup

    visit board_path(board)

    within_section(todo.name) { assert_text edit.name }
    within_section(doing.name) { assert_text write.name }
    within_section(done.name) { assert_text setup.name }
  end
end
