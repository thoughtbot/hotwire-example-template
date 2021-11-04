class Search
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :q, :string
  attribute :deactivated, :boolean

  def query(scope)
    to_h.values.reduce(scope) { |query, conditions| query.where(*conditions) }
  end

  def to_h
    {
      deactivated_on: ([ deactivated_on: (..Date.current) ] if deactivated),
      q: ([ "name ILIKE :query OR email_address ILIKE :query", query: q + "%" ] if q.present?),
    }.compact_blank
  end
end
