class AddShopifyOptions < ActiveRecord::Migration
  def up
    create_table(:shopify_options, id: false ) do |t|

      t.integer :id, limit: 8
      t.integer :product_id, limit: 8
      t.string :name
      t.text :values
      t.integer :position
      


    end
    execute "ALTER TABLE shopify_options ADD PRIMARY KEY (id);"
  end

  def down
    drop_table :shopify_options
  end
end
