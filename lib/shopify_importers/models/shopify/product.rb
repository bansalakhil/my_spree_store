class Shopify::Product < Shopify::Importer
  # self.site = Shopify.store_url
  self.site = "http://instanatural.com"
  self.collection_name = "products"
  self.include_root_in_json =  true
  self.logger = Rails.logger

  attr_accessor :imported_product

  def self.default_shipping_category
    @@default_shipping_category ||= Spree::ShippingCategory.find_or_create_by(name: Shopify.config[:shipping_category])
  end

  def self.fetch_and_import(page: 1, per_page: Shopify.config[:per_page])
    # products = fetch_all(page: page, per_page: per_page)
    products = Shopify::Product.find(:all, {limit: 250})

    Spree::Product.transaction do 
      products.collect!(&:import)
    end
    products
  end


  def import 

    record = Spree::Product.new(
                                  # id: id,
                                  name: title,
                                  description: body_html,
                                  slug: handle,
                                  available_on: published_at,
                                  price: default_variant.price,
                                  shipping_category: Shopify::Product.default_shipping_category,
                                  prototype_id: product_prototype_id,
                                  created_at: created_at,
                                  updated_at: updated_at                                  
      )

    # set master variant's sku
    record.sku = default_variant.sku if variants.size == 1

    unless record.save
      Rails.logger.debug "\n\n"
      Rails.logger.debug "#" * 80
      Rails.logger.debug "Could not save #{record.class}: #{record.inspect}"
      Rails.logger.debug "\n"
      Rails.logger.debug "Creating #{record.class} Shopify Data:  #{self.inspect}"
      Rails.logger.debug "\n"
      Rails.logger.debug "Errors: #{record.errors.inspect}"
      Rails.logger.debug "\n"
      Rails.logger.debug "#" * 80
      raise "Could not save #{record.class}, see log above \n\n"
    end

    # Create images
    if images.present?
      threads = []
      images.sort_by{|i| i.position}.each do |shopify_image|
        threads << fork do
          image = Spree::Image.new(created_at: shopify_image.created_at, updated_at: shopify_image.updated_at)
          image.attachment = shopify_image.src 
          record.master_images << image if image.save
        end
      end
       threads.each { |thr| Process.waitpid(thr) }
    end


    if variants.size > 1
      
      # Create option type option values
      options.each do |option|
        option_type_name =  get_option_type_name(option)
        spree_option_type = Spree::OptionType.find_by(name: option_type_name)
        if spree_option_type.nil?
          spree_option_type = Spree::OptionType.create!(name: option_type_name, presentation: option.name)
          option.values.each do |ov|
            spree_option_type.option_values.create!(name: ov, presentation: ov)
          end
        end
        record.option_types << spree_option_type
      end

      # create variants
      variants.each do |variant|
        spree_variant = build_variant(record, variant)
        
        [1, 2, 3].each do |i|
          variant_option_value = variant.send("option#{i}")
          variant_option_type = options.find{|op| op.position == i}

          if variant_option_type && variant_option_value
            spree_option_type = Spree::OptionType.find_by(name: get_option_type_name(variant_option_type))
            spree_option_value = spree_option_type.option_values.find_by(name: variant_option_value)
            
            if spree_option_value
              spree_variant.option_values << spree_option_value

            end
          end
        end

        spree_variant.save
      end

    end


    self.imported_product = record
    self
  end

  def get_option_type_name(option)
    product_type.blank? ? option.name : "#{product_type}-#{option.name}"
  end

  def build_variant(spree_product, variant)
    spree_variant = spree_product.variants.build(
                      sku: variant.sku,
                      weight: variant.grams,
                      price: variant.price,
                      # is_master: (variant.position == 1),
                    )
  end

  def default_variant
    @default_variant ||= variants.first{|x| x.position == 1}
  end

  def product_prototype_id
    if product_type.present?
      prototype = Spree::Prototype.find_or_create_by(name: product_type)
      prototype.id
    end
  end



# {
#   "customer": {
#     "first_name": "Steve",
#     "last_name": "Lastnameson",
#     "email": "steve.lastnameson@example.com",
#     "verified_email": true,
#     "addresses": [
#       {
#         "address1": "123 Oak St",
#         "city": "Ottawa",
#         "province": "ON",
#         "phone": "555-1212",
#         "zip": "123 ABC",
#         "last_name": "Lastnameson",
#         "first_name": "Mother",
#         "country": "CA"
#       }
#     ],
#     "metafields": [
#       {
#         "key": "new",
#         "value": "newvalue",
#         "value_type": "string",
#         "namespace": "global"
#       }
#     ]
#   }
# }



  @@countries =  nil
  def self.get_fake_customer

    args = {
              first_name: Faker::Name.first_name, 
              last_name: Faker::Name.last_name,
              email: Faker::Name.first_name + "@yahoo.com",
              verified_email: true
    }

    customer = new(args)
    address = Shopify::Address.new(
                                    first_name: Faker::Name.first_name, 
                                    last_name: Faker::Name.last_name,
                                    address1: Faker::Address.street_address,
                                    city: Faker::Address.city,
                                    country: "US",
                                    province:  "FL",
                                    created_at: created_at,
                                    updated_at: updated_at
      )

    metafield = Shopify::Metafield.new(
                                          key: Faker::Lorem.word,
                                          value: Faker::Lorem.sentence,
                                          value_type: "string",
                                          namespace: "global"
      )


    customer.addresses = [address]
    customer.metafields = [metafield]
    customer
  end

end


# 4.times do
#   fork{
#     100.times do 
#       c = Shopify::Customer.get_fake_customer
#       c.save
#     end
#   }
# end
# 
