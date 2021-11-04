class Search
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :q, :string
  attribute :deactivated, :boolean
  attribute :first_purchase_on_minimum, :date
  attribute :first_purchase_on_maximum, :date

  def query(scope)
    to_h.values.reduce(scope) { |query, conditions| query.where(*conditions) }
  end

  def to_h
    {
      deactivated_on: ([ deactivated_on: (..Date.current) ] if deactivated),
      first_purchase_on: ([ first_purchase_on: first_purchase_on ] if first_purchase_on.present?),
      q: ([ "name ILIKE :query OR email_address ILIKE :query", query: q + "%" ] if q.present?),
    }.compact_blank
  end

  private

  def first_purchase_on
    if first_purchase_on_minimum || first_purchase_on_maximum
      Range.new(first_purchase_on_minimum, first_purchase_on_maximum)
    end
  end
end
