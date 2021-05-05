class CreateUploads < ActiveRecord::Migration[7.0]
  def change
    create_table :uploads do |t|

      t.timestamps
    end
  end
end
