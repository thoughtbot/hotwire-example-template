class Document < ApplicationRecord
  enum :access, publish: 0, draft: 1, passcode_protect: 2

  has_rich_text :content

  with_options presence: true do
    validates :content
    validates :passcode, if: :passcode_protect?
  end
end
