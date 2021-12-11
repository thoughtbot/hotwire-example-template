class CreateTasks < ActiveRecord::Migration[7.0]
  def change
    create_table :tasks do |t|
      t.text :details
      t.datetime :done_at

      t.timestamps
    end
  end
end
