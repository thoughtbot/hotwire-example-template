require "application_system_test_case"

class InvitationCodesTest < ApplicationSystemTestCase
  test "copy code to clipboard" do
    code = "secret"

    visit invitation_code_path(id: code)
    click_on "Copy to clipboard"
    send_keys(:tab).then { assert_field "Invitation code", focused: true }
    send_keys :meta, "v"

    assert_field "Invitation code", focused: true, with: code
  end
end
