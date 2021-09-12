require "test_helper"

class ApplicantTest < ActiveSupport::TestCase
  test "requires name" do
    applicant = Applicant.new name: ""

    valid = applicant.validate

    assert_not valid
    assert_includes applicant.errors, :name
  end

  test "requires at least one Personal Reference" do
    applicant = Applicant.new name: "An Applicant",
                              references_attributes: [{ name: "", email_address: "" }]

    valid = applicant.validate

    assert_not valid
    assert_includes applicant.errors, :references
  end
end
