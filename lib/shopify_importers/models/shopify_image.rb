class ShopifyImage < ActiveRecord::Base
  self.primary_key = :id

  ATTRIBUTES = [:id, :product_id, :src, :variant_ids, :position, :created_at, :updated_at]

  belongs_to :shopify_product, foreign_key: :product_id

end

