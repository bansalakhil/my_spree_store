class ShopifyProduct < ActiveRecord::Base
  self.primary_key = :id

  ATTRIBUTES = [ :id, :title, :body_html, :vendor, :product_type, :handle, :template_suffix, :published_scope, :tags, :created_at, :updated_at, :published_at ]


  has_many :shopify_variants, foreign_key: :product_id
  has_many :shopify_options, foreign_key: :product_id
  has_many :shopify_images, foreign_key: :product_id

end

