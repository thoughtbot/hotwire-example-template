class CreatePlayers < ActiveRecord::Migration[7.0]
  def change
    create_table :players do |t|
      t.string :player_id, null: false
      t.string :common_name, null: false
      t.string :league, null: false
      t.boolean :hof, null: false
      t.integer :start_year, null: false
      t.integer :end_year, null: false
      t.integer :total_games, null: false
      t.string :player_label, null: false
      t.string :position_cat, null: false
      t.string :position, null: false

      t.timestamps
    end
  end
end
