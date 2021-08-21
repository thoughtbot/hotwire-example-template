class CreateMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :messages do |t|
      t.string :sender, null: false
      t.string :recipient, null: false

      t.timestamps
    end
  end
end
