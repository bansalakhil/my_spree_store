class ShopifyOption < ActiveRecord::Base
  self.primary_key = :id

  ATTRIBUTES = [:id, :product_id, :name, :values, :position]

  belongs_to :shopify_product, foreign_key: :product_id


end

