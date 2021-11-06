class CreateMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :messages do |t|
      t.belongs_to :sender, null: false, foreign_key: { to_table: :users }
      t.belongs_to :recipient, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
