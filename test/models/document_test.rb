require "test_helper"

class DocumentTest < ActiveSupport::TestCase
  test "validates the presence of content" do
    document = Document.new

    valid = document.validate

    assert_not valid
    assert_includes document.errors, :content
  end

  test "does not validates the presence of passcode for a published Document" do
    document = Document.new access: "publish"

    valid = document.validate

    assert_not valid
    assert_not_includes document.errors, :passcode
  end

  test "does not validates the presence of passcode for a draft Document" do
    document = Document.new access: "draft"

    valid = document.validate

    assert_not valid
    assert_not_includes document.errors, :passcode
  end

  test "validates the presence of passcode when passcode protect Document" do
    document = Document.new access: "passcode_protect"

    valid = document.validate

    assert_not valid
    assert_includes document.errors, :passcode
  end
end
