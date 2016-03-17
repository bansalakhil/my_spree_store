class ShopifyCustomer < ActiveRecord::Base
  self.primary_key = :id

  ATTRIBUTES = [:id, :email, :accepts_marketing, :created_at, :updated_at, :first_name, :last_name, :orders_count, :state, :total_spent, :last_order_id, :note, :verified_email, :multipass_identifier, :tax_exempt, :tags, :last_order_name]

  has_many :shopify_addresses, foreign_key: :customer_id


end

