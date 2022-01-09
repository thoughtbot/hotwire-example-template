class Building < ApplicationRecord
  enum :building_type, owned: 0, leased: 1, other: 2

  with_options presence: true do
    validates :line_1
    validates :line_2
    validates :city
    validates :postal_code
  end

  validates :state, inclusion: { in: -> record { record.states.keys }, allow_blank: true },
                    presence: { if: -> record { record.states.present? } }

  validates :management_phone_number, presence: { if: :leased? }
  validates :building_type_description, presence: { if: :other? }

  def countries
    CS.countries.with_indifferent_access
  end

  def country_name
    countries[country]
  end

  def states
    CS.states(country).with_indifferent_access
  end

  def state_name
    states[state]
  end

  def estimated_arrival_on
    countries.keys.index(country).days.from_now
  end
end
