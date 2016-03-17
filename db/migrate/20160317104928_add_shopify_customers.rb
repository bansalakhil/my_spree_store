class AddShopifyCustomers < ActiveRecord::Migration
  def up
    create_table(:shopify_customers, id: false ) do |t|

      t.integer :id, limit: 8

      t.string :email
      t.boolean :accepts_marketing
      t.string :first_name
      t.string :last_name
      t.integer :orders_count
      t.string :state
      t.string :total_spent
      t.integer :last_order_id, limit: 8
      t.text :note
      t.boolean :verified_email
      t.string :multipass_identifier
      t.boolean :tax_exempt
      t.string :tags
      t.string :last_order_name
    
      t.datetime :created_at
      t.datetime :updated_at
      


    end
    execute "ALTER TABLE shopify_customers ADD PRIMARY KEY (id);"
  end

  def down
    drop_table :shopify_customers
  end
end
