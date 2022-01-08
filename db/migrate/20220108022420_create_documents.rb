class CreateDocuments < ActiveRecord::Migration[7.0]
  def change
    create_table :documents do |t|
      t.integer :access, null: false, default: 0

      t.text :passcode

      t.timestamps
    end
  end
end
