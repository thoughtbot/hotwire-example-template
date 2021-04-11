require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test "#mentioned_users returns the User records attached to the content" do
    alice_to_bob = messages(:alice_to_bob)
    bob = users(:bob)

    mentioned_users = alice_to_bob.mentioned_users

    assert_equal [ bob ], mentioned_users
  end
end
