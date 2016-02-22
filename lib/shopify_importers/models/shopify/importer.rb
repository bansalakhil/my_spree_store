class Shopify::Importer < ActiveResource::Base



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




end