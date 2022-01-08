class CreateAddresses < ActiveRecord::Migration[7.0]
  def change
    create_table :addresses do |t|
      t.string :line_1, null: false
      t.string :line_2
      t.string :city, null: false
      t.string :state
      t.string :postal_code, null: false
      t.string :country, null: false, default: "US"

      t.timestamps
    end
  end
end
