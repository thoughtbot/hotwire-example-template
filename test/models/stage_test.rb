require "test_helper"

class StageTest < ActiveSupport::TestCase
  test "#other_stages" do
    todo, doing, done = stages :todo, :doing, :done

    other_stages = todo.other_stages

    assert_equal [ doing, done ], other_stages.in_order_of(:id, [ doing.id, done.id ])
  end
end
