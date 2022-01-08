require "application_system_test_case"

class DocumentsTest < ApplicationSystemTestCase
  test "saves a valid published Document" do
    visit new_document_path
    assert_no_changes -> { page.has_field? "Passcode", fieldset: "Passcode protect" } do
      choose("Publish", fieldset: "Access")
    end
    within :section, "New document" do
      fill_in_rich_text_area "Content", with: "Some publicly accessible content"
      click_on "Create Document"
    end

    within :section, "Publish" do
      assert_text "Some publicly accessible content"
    end
    assert_no_selector :alert
  end

  test "saves a valid draft Document" do
    visit new_document_path
    assert_no_changes -> { page.has_field? "Passcode", fieldset: "Passcode protect" } do
      choose("Draft", fieldset: "Access")
    end
    within :section, "New document" do
      fill_in_rich_text_area "Content", with: "Some private, draft content"
      click_on "Create Document"
    end

    within :section, "Draft" do
      assert_text "Some private, draft content"
    end
    assert_no_selector :alert
  end

  test "saves a valid Passcode protect Document" do
    visit new_document_path
    assert_no_changes -> { page.has_field? "Passcode", fieldset: "Passcode protect" } do
      choose("Passcode protect", fieldset: "Access")
    end
    within :section, "New document" do
      fill_in "Passcode", with: "secretcode", fieldset: "Passcode protect"
      fill_in_rich_text_area "Content", with: "A document only accessible with the passcode"
      click_on "Create Document"
    end

    within :section, "Passcode protect" do
      assert_text "A document only accessible with the passcode"
    end
    assert_no_selector :alert
  end

  test "rejects an invalid published Document" do
    visit new_document_path
    choose("Publish", fieldset: "Access")
    within :section, "New document" do
      click_on "Create Document"
    end

    assert_selector :section, "New document"
    assert_selector :alert, "Content can't be blank"
    assert_no_selector :alert, "Passcode can't be blank"
  end

  test "rejects an invalid draft Document" do
    visit new_document_path
    choose("Draft", fieldset: "Access")
    within :section, "New document" do
      click_on "Create Document"
    end

    assert_selector :section, "New document"
    assert_selector :alert, "Content can't be blank"
    assert_no_selector :alert, "Passcode can't be blank"
  end

  test "rejects an invalid Passcode protect Document" do
    visit new_document_path
    choose("Passcode protect", fieldset: "Access")
    within :section, "New document" do
      click_on "Create Document"
    end

    assert_selector :section, "New document"
    assert_selector :alert, "Content can't be blank"
    assert_selector :alert, "Passcode can't be blank"
  end
end
