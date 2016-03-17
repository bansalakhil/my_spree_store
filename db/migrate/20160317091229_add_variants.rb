class AddVariants < ActiveRecord::Migration
  
  def up
    create_table(:shopify_variants, id: false ) do |t|

      t.integer :id, limit: 8
      t.integer :product_id, limit: 8
      t.string :title
      t.string :price
      t.string :sku
      t.integer :position
      t.integer :grams
      t.string :inventory_policy
      t.string :compare_at_price
      t.string :fulfillment_service
      t.string :inventory_management
      t.string :option1
      t.string :option2
      t.string :option3
      t.boolean :requires_shipping
      t.boolean :taxable
      t.string :barcode
      t.integer :inventory_quantity
      t.integer :old_inventory_quantity
      t.integer :image_id
      t.integer :weight
      t.string :weight_unit

      t.datetime :created_at
      t.datetime :updated_at
      


    end
    execute "ALTER TABLE shopify_variants ADD PRIMARY KEY (id);"
  end

  def down
    drop_table :shopify_variants
  end

end
