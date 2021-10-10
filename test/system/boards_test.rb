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

  test "drag a Card to another Stage" do
    todo, doing = stages :todo, :doing
    edit, top_of_doing = cards :edit, :write

    visit board_path(todo.board)
    drag_card edit.name, onto: top_of_doing.name

    within_section(todo.name) { assert_no_text edit.name }
    within_section doing.name do
      assert_css "li:nth-of-type(1)", text: top_of_doing.name
      assert_css "li:nth-of-type(2)", text: edit.name
    end
  end

  test "drag a Card to an empty Stage" do
    todo, doing = stages :todo, :doing
    edit, write = cards :edit, :write
    doing.cards.without(write).destroy_all

    visit board_path(todo.board)
    drag_card write.name, onto: edit.name
    drag_card write.name, onto: "Move to #{doing.name}"

    within_section(todo.name) { assert_no_text write.name }
    within_section(doing.name) { assert_css "li:only-of-type", text: write.name }
  end

  test "receives changes within a Stage broadcast from other sessions" do
    todo = stages :todo
    first, middle, last = cards :edit, :pull_request, :publish

    visit board_path(todo.board)
    within_window open_new_window do
      visit board_path(todo.board)
      within_section(todo.name) { click_on "Move #{middle.name} up" }
    end

    within_section todo.name do
      assert_css "li:nth-of-type(1)", text: middle.name
      assert_css "li:nth-of-type(2)", text: first.name
      assert_css "li:nth-of-type(3)", text: last.name
    end
  end

  test "receives changes across a Stage broadcast from other sessions" do
    todo, doing = stages :todo, :doing
    edit, top_of_doing = cards :edit, :write

    visit board_path(todo.board)
    within_window open_new_window do
      visit board_path(todo.board)
      drag_card edit.name, onto: top_of_doing.name
    end

    within_section(todo.name) { assert_no_text edit.name }
    within_section doing.name do
      assert_css "li:nth-of-type(1)", text: top_of_doing.name
      assert_css "li:nth-of-type(2)", text: edit.name
    end
  end

  test "preserves button focus when moving a Card down within a Stage" do
    todo = stages :todo
    first, middle, last = cards :edit, :pull_request, :publish

    visit board_path(todo.board)
    within_section todo.name do
      move_focus_to "Move #{first.name} down"
      send_keys :enter

      assert_button "Move #{first.name} down", focused: true
      send_keys :enter

      assert_css "li:nth-of-type(1)", text: middle.name
      assert_css "li:nth-of-type(2)", text: last.name
      assert_css "li:nth-of-type(3)", text: first.name
    end
  end

  test "releases button focus when the button is hidden" do
    todo = stages :todo
    middle = cards :pull_request

    visit board_path(todo.board)
    within_section todo.name do
      move_focus_to "Move #{middle.name} down"
      send_keys :enter

      assert_css "li:nth-of-type(3)", text: middle.name
      assert_no_button focused: true, visible: :all
    end
  end

  test "preserves focus when receiving changes from another session" do
    todo = stages :todo
    first, middle = cards :edit, :pull_request

    visit board_path(todo.board)
    move_focus_to "Move #{first.name} down"
    within_window open_new_window do
      visit board_path(todo.board)
      within_section(todo.name) { click_on "Move #{middle.name} up" }
    end

    within_section todo.name do
      assert_button "Move #{first.name} down", focused: true
      assert_css "li:nth-of-type(1)", text: middle.name
      assert_css "li:nth-of-type(2)", text: first.name
    end
  end

  def move_focus_to(selector = :link_or_button, locator, **options)
    send_keys :tab until page.has_selector?(selector, locator, focused: true, **options)
  end

  def drag_card(name, onto:)
    drag_target = find %([draggable="true"]), text: name
    drop_target = find %([aria-dropeffect="move"]), text: onto

    drag_target.drag_to drop_target
  end
end
