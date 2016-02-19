class Shopify::Customer < ActiveResource::Base
  self.site = Shopify.store_url
  self.collection_name = "customers"
  self.include_root_in_json =  true
  self.logger = Rails.logger


  attr_accessor :imported_user

  has_many :metafields, class_name: "shopify/metafield"
  has_many :addresses, class_name: "shopify/addresses"





  class << self
    def fetch_all(page: 1, per_page: Shopify.config[:per_page])
      total = get(:count)
      Rails.logger.debug "Total records in shopify: #{total}"
      customers = []
      while( (customer_batch = find(:all, params: {limit: per_page, page: page})).size > 0 )
        Rails.logger.debug "Fetching  page: #{page}"
        # Rails.logger.debug "############################################################ #{customer_batch.size}}"
        customers.concat(customer_batch)
        page += 1
      end

      if total != customers.size
        Rails.logger.debug "#" *80
        Rails.logger.debug "#" *80
        Rails.logger.debug "#" *80
        Rails.logger.debug "#" *80
        Rails.logger.debug "Total #{total} records exists on shopify, but only #{customers.size} were fetched"
        Rails.logger.debug "#" *80
        Rails.logger.debug "#" *80
        Rails.logger.debug "#" *80
        Rails.logger.debug "#" *80
      end

      customers
    end


    def fetch_and_import(page: 1, per_page: Shopify.config[:per_page])
      customers = fetch_all(page: page, per_page: per_page)

      Spree::user_class.transaction do 
        customers.collect!(&:import)
      end
      customers
    end



  end


  def import 
    country = Spree::Country.find_by(iso: default_address.country_code)
    random_password = SecureRandom.hex(8)

    address = {
                firstname: default_address.first_name,
                lastname: default_address.last_name,
                address1: default_address.address1,
                address2: default_address.address2,
                company: default_address.company,                  
                city: default_address.city,
                zipcode: default_address.zip || "00000",
                phone: default_address.phone || "0000000000",
                country: country,
                state: country.states.find_by(abbr: default_address.province_code)
    }

    user = Spree.user_class.create(
                                  # id: id,
                                  email: email,
                                  password: random_password,
                                  password_confirmation: random_password,
                                  bill_address_attributes: address,
                                  ship_address_attributes: address
      )

    self.imported_user = user
    self
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
4.times do
  fork{
    100.times do 
      c = Shopify::Customer.get_fake_customer
      c.save
    end
  }
end