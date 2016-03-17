class AddShopifyImage < ActiveRecord::Migration
  def up
    create_table(:shopify_images, id: false ) do |t|

      t.integer :id, limit: 8
      t.integer :product_id, limit: 8
      t.integer :position

      t.text :src
      t.text :variant_ids
      

      t.datetime :created_at
      t.datetime :updated_at


    end
    execute "ALTER TABLE shopify_images ADD PRIMARY KEY (id);"
  end

  def down
    drop_table :shopify_images
  end
end
