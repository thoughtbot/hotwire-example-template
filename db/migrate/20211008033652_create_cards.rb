class CreateCards < ActiveRecord::Migration[7.0]
  def change
    create_table :cards do |t|
      t.integer :row_order
      t.belongs_to :stage, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
