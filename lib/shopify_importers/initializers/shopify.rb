class Shopify



  class << self
    
    def load_config 
      Rails.logger.debug "loading config file"
      config_file = File.join(Rails.root, 'lib', 'shopify_importers', 'config.yml')
      config = YAML.load(File.read(config_file))
      config = config[Rails.env]
      HashWithIndifferentAccess.new(config)
    end

    def config
      @@config ||= load_config
    end

    def store_url #(resource)
      "https://" + config[:api_key] + ":" + config[:api_password] + "@" + config[:store_domain] + "/admin/" #+ resource + ".json"
    end
  end



end