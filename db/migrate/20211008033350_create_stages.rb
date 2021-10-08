class CreateStages < ActiveRecord::Migration[7.0]
  def change
    create_table :stages do |t|
      t.text :name, null: false
      t.integer :column_order
      t.belongs_to :board, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
