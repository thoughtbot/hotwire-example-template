class Task < ApplicationRecord
  validates :details, presence: true

  attribute :done, :boolean

  scope :to_do, -> { order(created_at: :asc).where done_at: nil }
  scope :done, -> { order(done_at: :asc).where.not done_at: nil }

  def done
    done_at.present? && done_at.past?
  end

  def done=(*)
    super

    self.done_at = read_attribute(:done) ? Time.current : nil
  end
end
