class ShopifyAddress < ActiveRecord::Base
  self.primary_key = :id

  ATTRIBUTES = [:address1, :address2, :city, :company, :country, :country_code, :country_name, :default, :first_name, :id, :last_name, :name, :phone, :province, :province_code, :zip]

   belongs_to :shopify_customer, foreign_key: :customer_id

end

