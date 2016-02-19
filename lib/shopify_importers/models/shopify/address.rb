class Shopify::Address < ActiveResource::Base
  self.site = Shopify.store_url
  self.collection_name = "addresses"


end