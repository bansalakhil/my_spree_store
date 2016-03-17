class AddShopifyAddresses < ActiveRecord::Migration
  def up
    create_table(:shopify_addresses, id: false ) do |t|

      t.integer :id, limit: 8
      t.integer :customer_id, limit: 8


      t.string :first_name
      t.string :last_name
      t.string :company
      t.string :address1
      t.string :address2
      t.string :city
      t.string :province
      t.string :country
      t.string :zip
      t.string :phone
      t.string :name
      t.string :province_code
      t.string :country_code
      t.string :country_name
      t.boolean :default


    end
    execute "ALTER TABLE shopify_addresses ADD PRIMARY KEY (id);"
  end

  def down
    drop_table :shopify_addresses
  end
end
