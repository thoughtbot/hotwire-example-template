class CreateBuildings < ActiveRecord::Migration[7.0]
  def change
    create_table :buildings do |t|
      t.integer :building_type, null: false, default: 0

      t.string :line_1, null: false
      t.string :line_2
      t.string :city, null: false
      t.string :state
      t.string :postal_code, null: false
      t.string :country, null: false, default: "US"
      t.string :management_phone_number
      t.text :building_type_description

      t.timestamps
    end
  end
end
