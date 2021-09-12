class Reference < ApplicationRecord
  belongs_to :applicant

  with_options presence: true do
    validates :name
    validates :email_address
  end
end
