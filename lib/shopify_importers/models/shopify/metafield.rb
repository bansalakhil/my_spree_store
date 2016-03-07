class Shopify::Metafield < Shopify::Importer
  self.site = Shopify.store_url
  self.collection_name = "metafields"


end