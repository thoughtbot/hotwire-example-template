class CreateDraftings < ActiveRecord::Migration[7.0]
  def change
    create_table :draftings do |t|
      t.belongs_to :player, null: false, foreign_key: { cascade: :delete }
      t.belongs_to :team, null: false, foreign_key: { cascade: :delete }

      t.timestamps
    end
  end
end
