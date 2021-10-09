class Card < ApplicationRecord
  include RankedModel

  belongs_to :stage

  has_rich_text :content

  ranks :row_order, with_same: :stage_id

  delegate :other_stages, to: :stage

  def name
    content.to_plain_text
  end

  def broadcast_changes_to_stages
    changed_stages.each { |stage| stage.broadcast_replace_later_to stage.board }
  end

  private

  def changed_stages
    stage.board.stages.find changed_stage_ids
  end

  def changed_stage_ids
    saved_change_to_stage_id.presence || [ stage_id ]
  end
end
