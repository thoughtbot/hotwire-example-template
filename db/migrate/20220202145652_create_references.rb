class CreateReferences < ActiveRecord::Migration[7.0]
  def change
    create_table :references do |t|
      t.belongs_to :applicant, null: false, foreign_key: true

      t.text :name, null: false
      t.text :email_address, null: false

      t.timestamps
    end
  end
end
