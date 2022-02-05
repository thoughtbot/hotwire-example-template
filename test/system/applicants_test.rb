require "application_system_test_case"

class ApplicantsTest < ApplicationSystemTestCase
  test "new presents a form to collect Applicant data" do
    visit new_applicant_path; sleep 0.2
    within :fieldset, "Applicant" do
      fill_in "Name", with: "Bob"
    end
    within :fieldset, "Personal references" do
      click_on "Add personal reference"
      within "li:nth-of-type(1)" do
        fill_in "Name", with: "Friend"
        fill_in "Email address", with: "friend@example.com"
      end
      click_on "Add personal reference"
      within "li:nth-of-type(2)" do
        fill_in "Name", with: "Enemy"
        fill_in "Email address", with: "enemy@example.com"
      end
    end
    click_on "Create Applicant"

    within :section, "Bob" do
      assert_text "Friend", count: 1
      assert_text "friend@example.com", count: 1
      assert_text "Enemy", count: 1
      assert_text "enemy@example.com", count: 1
    end
  end

  test "edit presents a form to edit Applicant data" do
    alice = applicants :alice

    visit edit_applicant_path(alice); sleep 0.2
    within :fieldset, "Applicant" do
      fill_in "Name", with: "Alicia"
    end
    within :fieldset, "Personal references" do
      click_on "Add personal reference"
      within "li:nth-of-type(2)" do
        fill_in "Name", with: "Enemy"
        fill_in "Email address", with: "enemy@example.com"
      end
    end
    click_on "Update Applicant"

    within :section, "Alicia" do
      assert_text "Friend", count: 1
      assert_text "friend@example.com", count: 1
      assert_text "Enemy", count: 1
      assert_text "enemy@example.com", count: 1
    end
  end

  test "rejects invalid nested attributes for Personal References when creating" do
    visit new_applicant_path; sleep 0.2
    within :fieldset, "Applicant" do
      fill_in "Name", with: "New Applicant"
    end
    within :fieldset, "Personal references" do
      click_on "Add personal reference"
      within "li:nth-of-type(1)" do
        fill_in "Name", with: ""
        fill_in "Email address", with: "friend@example.com"
      end
      click_on "Add personal reference"
      within "li:nth-of-type(2)" do
        fill_in "Name", with: "Enemy"
        fill_in "Email address", with: "enemy@example.com"
        check "Destroy"
      end
    end
    click_on "Create Applicant"

    assert_field "Email address", with: "friend@example.com"
    assert_unchecked_field "Destroy", count: 1
    assert_no_field "Email address", with: "enemy@example.com"
  end

  test "rejects invalid nested attributes for Personal References when updating" do
    alice = applicants :alice
    friend = references :friend

    visit edit_applicant_path(alice); sleep 0.2
    within :fieldset, "Applicant" do
      fill_in "Name", with: "Alicia"
    end
    within :fieldset, "Personal references" do
      check "Destroy"
      click_on "Add personal reference"
      within "li:nth-of-type(2)" do
        fill_in "Name", with: ""
        fill_in "Email address", with: "enemy@example.com"
      end
    end
    click_on "Update Applicant"

    assert_field "Name", with: "Alicia", fieldset: "Applicant"
    within :fieldset, "Personal references" do
      assert_no_field "Name", with: friend.name
      assert_no_field "Email address", with: friend.email_address
      assert_field "Name", with: "", count: 1
      assert_field "Email address", with: "enemy@example.com"
      assert_unchecked_field "Destroy", count: 1
    end
  end

  test "form is keyboard navigable" do
    visit new_applicant_path
    send_keys(:tab).then { send_keys "Bob" }
    send_keys(:tab).then { send_keys :enter }
    4.times { send_keys [ :shift, :tab ] }
    send_keys(:tab).then { send_keys "Enemy" }
    send_keys(:tab).then { send_keys "enemy@example.com" }
    send_keys(:tab).then { send_keys :space }
    send_keys(:tab).then { send_keys :enter }
    4.times { send_keys [ :shift, :tab ] }
    send_keys(:tab).then { send_keys "Friend" }
    send_keys(:tab).then { send_keys "friend@example.com" }
    send_keys(:enter)

    within :section, "Bob" do
      assert_no_text "Enemy"
      assert_no_text "enemy@example.com"
      assert_text "Friend", count: 1
      assert_text "friend@example.com", count: 1
    end
  end
end
