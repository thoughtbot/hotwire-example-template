class Search
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :q, :string

  def query(scope)
    to_h.values.reduce(scope) { |query, conditions| query.where(*conditions) }
  end

  def to_h
    {
      q: ([ "name ILIKE :query OR email_address ILIKE :query", query: q + "%" ] if q.present?),
    }.compact_blank
  end
end
