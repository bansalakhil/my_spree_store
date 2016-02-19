class Shopify::Metafield < ActiveResource::Base
  self.site = Shopify.store_url
  self.collection_name = "metafields"


end