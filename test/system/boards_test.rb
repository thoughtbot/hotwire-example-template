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

  test "omits redundant buttons for the first and last Cards in a Stage" do
    todo = stages :todo
    first, middle, last = cards :edit, :pull_request, :publish

    visit board_path(todo.board)

    within_section todo.name do
      assert_no_button "Move #{first.name} up"
      assert_button "Move #{middle.name} up"
      assert_button "Move #{middle.name} down"
      assert_no_button "Move #{last.name} down"
    end
  end

  test "move a Card to another Stage" do
    todo, doing = stages :todo, :doing
    edit, top_of_doing = cards :edit, :write

    visit board_path(todo.board)
    within_section todo.name do
      within "li", text: edit.name do
        select doing.name, from: "Stages"
        click_on "Move to Stage"
      end

      assert_no_text edit.name
    end
    within_section doing.name do
      assert_css "li:nth-of-type(1)", text: edit.name
      assert_css "li:nth-of-type(2)", text: top_of_doing.name
    end
  end

  test "drag a Card to sort within a Stage" do
    todo = stages :todo
    first, middle, last = cards :edit, :pull_request, :publish

    visit board_path(todo.board)
    within_section todo.name do
      drag_card last.name, onto: first.name

      assert_css "li:nth-of-type(1)", text: last.name
      assert_css "li:nth-of-type(2)", text: first.name
      assert_css "li:nth-of-type(3)", text: middle.name
    end
  end

  def drag_card(name, onto:)
    drag_target = find %([draggable="true"]), text: name
    drop_target = find %([aria-dropeffect="move"]), text: onto

    drag_target.drag_to drop_target
  end
end
