class Shopify::Importer < ActiveResource::Base
  self.site = Shopify.store_url
  self.include_root_in_json =  true
  self.logger = Rails.logger

  def self.fetch_resources(limit: 50, page: 1)
    begin
      find(:all, params: {limit: limit, page: page})
    rescue ActiveResource::ClientError => e
      Rails.logger.debug "Exception occurred: #{e.message}. Waiting for #{Shopify.config[:wait_time]} seconds before retrying"
      sleep Shopify.config[:wait_time]
      retry
    end        
  end

  def self.fetch_all(page: 1, per_page: Shopify.config[:per_page])
    total = get(:count)
    Rails.logger.debug "Total records(#{self.to_s}) in shopify: #{total}"
    resources = []

    while( (resource_batch = fetch_resources(limit: per_page, page: page) ).size > 0 )
        Rails.logger.debug "Fetching page: #{page}"
        resources.concat(resource_batch)
        page += 1
    end

    if total != resources.size
      msg = "Total #{total} records(#{self.to_s}) exists on shopify, but only #{resources.size} were fetched"
      Rails.logger.debug "#" *80
      Rails.logger.debug msg
      Rails.logger.debug "#" *80
      raise msg
    end
    resources
  end

  def self.fetch_and_import(page: 1, per_page: Shopify.config[:per_page])
    shopify_records = fetch_all(page: page, per_page: per_page)

    ActiveRecord::Base.transaction do 
      shopify_records.map(&:import)
    end
    
    record_shopify_spree_object_ids(shopify_records)
    shopify_records
  end

  def self.record_shopify_spree_object_ids(records)
    file = File.join(Rails.root, 'log', self.to_s + '.csv')
    File.open(file, "w") do |f|
      f.puts "ShopifyType, ShopifyID, SpreeType, SpreeID"
      records.each do |record|
        f.puts "#{record.class}, #{record.id}, #{record.imported_record.class}, #{record.imported_record.id}"
      end
    end

    Rails.logger.info "%" *80
    Rails.logger.info "Shopify Spree object mapping written in: #{file}"
    Rails.logger.info "%" *80
  end

end