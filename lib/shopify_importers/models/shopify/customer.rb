class Shopify::Customer < Shopify::Importer
  self.collection_name = "customers"

  attr_accessor :imported_record

  has_many :metafields, class_name: "shopify/metafield"
  has_many :addresses, class_name: "shopify/addresses"

  def import 
    country = Spree::Country.find_by(iso: default_address.country_code)
    random_password = SecureRandom.hex(8)

    # Customer's default address
    address = {
                firstname: default_address.first_name,
                lastname: default_address.last_name,
                address1: default_address.address1,
                address2: default_address.address2,
                company: default_address.company,                  
                city: default_address.city,
                zipcode: default_address.zip.present? ? default_address.zip : "00000",
                phone: default_address.phone.present? ? default_address.phone : "0000000000",
                country: country,
                state: country.states.find_by(abbr: default_address.province_code)
    }

    # Spree user object
    spree_user = Spree.user_class.new(
                                  # id: id,
                                  email: email,
                                  password: random_password,
                                  password_confirmation: random_password,
                                  bill_address_attributes: address,
                                  ship_address_attributes: address,
                                  created_at: created_at,
                                  updated_at: updated_at
      )

    unless spree_user.save
      Rails.logger.debug "\n\n"
      Rails.logger.debug "#" * 80
      Rails.logger.debug "Could not save Spree::User: #{spree_user.inspect}"
      Rails.logger.debug "\n"
      Rails.logger.debug "Creating Spree::User Shopify Data:  #{self.inspect}"
      Rails.logger.debug "\n"
      Rails.logger.debug "Errors: #{spree_user.errors.full_messages}"
      Rails.logger.debug "\n"
      Rails.logger.debug "#" * 80
      raise "Could not save Spree::User, see log above \n\n"
    end

    self.imported_record = spree_user
    self
  end



##########################################################################

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

    shopify_customer = new(args)
    address = Shopify::Address.new(
                                    first_name: Faker::Name.first_name, 
                                    last_name: Faker::Name.last_name,
                                    address1: Faker::Address.street_address,
                                    city: Faker::Address.city,
                                    country: "US",
                                    province:  "FL"
      )

    metafield = Shopify::Metafield.new(
                                          key: Faker::Lorem.word,
                                          value: Faker::Lorem.sentence,
                                          value_type: "string",
                                          namespace: "global"
      )


    shopify_customer.addresses = [address]
    shopify_customer.metafields = [metafield]
    shopify_customer
  end


  def self.seed
    4.times do
      fork{
        100.times do 
          customer = Shopify::Customer.get_fake_customer
          customer.save
        end
      }
    end
  end

end

