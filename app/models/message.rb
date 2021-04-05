class Message < ApplicationRecord
  scope :containing, ->(query) { where <<~SQL, "%" + query + "%" }
    body ILIKE ?
  SQL
end
