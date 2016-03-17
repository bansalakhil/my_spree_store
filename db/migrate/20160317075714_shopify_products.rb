class ShopifyProducts < ActiveRecord::Migration
  def up
    create_table(:shopify_products, id: false ) do |t|
      t.integer :id, limit: 8

      t.string :title
      t.text :body_html
      t.string :vendor
      t.string :product_type
      t.string :handle
      t.string :template_suffix
      t.string :published_scope
      t.string :tags

      t.datetime :created_at
      t.datetime :updated_at
      t.datetime :published_at

    end
    execute "ALTER TABLE shopify_products ADD PRIMARY KEY (id);"
  end

  def down
    drop_table :shopify_products
  end
end
