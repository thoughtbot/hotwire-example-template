class CreateCategories < ActiveRecord::Migration[7.0]
  def change
    create_table :categories do |t|
      t.string :name, null: false

      t.timestamps
    end

    create_table :categorizations do |t|
      t.belongs_to :article, null: false
      t.belongs_to :category, null: false

      t.timestamps
    end
  end
end
