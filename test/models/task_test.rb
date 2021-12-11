require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "validates presence of details" do
    task = Task.new

    errors = task.tap(&:validate).errors

    assert_includes errors, :details
  end

  test ".done" do
    done_task =   Task.create! details: "done", done: true
    to_do_task = Task.create! details: "to_do", done: false

    done = Task.done

    assert_includes done, done_task
    assert_not_includes done, to_do_task
  end

  test ".to_do" do
    done_task =   Task.create! details: "done", done: true
    to_do_task = Task.create! details: "to_do", done: false

    to_do = Task.to_do

    assert_includes to_do, to_do_task
    assert_not_includes to_do, done_task
  end

  test "#done" do
    assert_predicate Task.new(done_at: Time.current), :done
    assert_not_predicate Task.new(done_at: nil), :done
  end

  test "#done=" do
    freeze_time do
      assert_equal Task.new(done: true).done_at, Time.current
      assert_equal Task.new(done: "1").done_at, Time.current
      assert_nil Task.new(done: false).done_at
      assert_nil Task.new(done: "0").done_at
    end
  end
end
