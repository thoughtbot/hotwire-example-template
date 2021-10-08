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

  test "move a Card down a Stage" do
    todo = stages :todo
    first, middle, last = cards :edit, :pull_request, :publish

    visit board_path(todo.board)
    within_section todo.name do
      click_on "Move #{middle.name} down"

      assert_css "li:nth-of-type(1)", text: first.name
      assert_css "li:nth-of-type(2)", text: last.name
      assert_css "li:nth-of-type(3)", text: middle.name
    end
  end

  test "move a Card up a Stage" do
    todo = stages :todo
    first, middle, last = cards :edit, :pull_request, :publish

    visit board_path(todo.board)
    within_section todo.name do
      click_on "Move #{middle.name} up"

      assert_css "li:nth-of-type(1)", text: middle.name
      assert_css "li:nth-of-type(2)", text: first.name
      assert_css "li:nth-of-type(3)", text: last.name
    end
  end
end
