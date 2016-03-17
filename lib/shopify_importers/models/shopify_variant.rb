class ShopifyVariant < ActiveRecord::Base
  self.primary_key = :id

  ATTRIBUTES = [:id, :product_id, :title, :price, :sku, :position, :grams, :inventory_policy, :compare_at_price, :fulfillment_service, :inventory_management, :option1, :option2, :option3, :created_at, :updated_at, :requires_shipping, :taxable, :barcode, :inventory_quantity, :old_inventory_quantity, :image_id, :weight, :weight_unit ]


  belongs_to :shopify_product, foreign_key: :product_id

end

