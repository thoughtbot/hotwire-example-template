class Player < ApplicationRecord
  def self.headings
    columns.reject { _1.name.in? %w[ id player_id created_at updated_at ] }
  end
end
