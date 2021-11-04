class CreateCustomers < ActiveRecord::Migration[7.0]
  def change
    create_table :customers do |t|
      t.text :name
      t.text :email_address
      t.date :first_purchase_on
      t.date :last_purchase_on
      t.date :deactivated_on

      t.timestamps
    end
    add_index :customers, :name
    add_index :customers, :email_address
    add_index :customers, :first_purchase_on
    add_index :customers, :last_purchase_on
    add_index :customers, :deactivated_on
  end
end
