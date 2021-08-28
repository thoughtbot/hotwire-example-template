class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    enable_extension "citext"
    create_table :users do |t|
      t.citext :username
      t.citext :name

      t.timestamps
    end
    add_index :users, :username
  end
end
