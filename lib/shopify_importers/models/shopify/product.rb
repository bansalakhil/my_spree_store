class Shopify::Product < Shopify::Importer
  # self.site = "http://instanatural.com"
  self.collection_name = "products"

  attr_accessor :imported_record


  # def self.fetch_and_import(page: 1, per_page: Shopify.config[:per_page])
  #   # products = fetch_all(page: page, per_page: per_page)
  #   products = Shopify::Product.find(:all, {limit: 250})

  #   Spree::Product.transaction do 
  #     products.collect!(&:import)
  #   end
  #   products
  # end


  def import 


    # save ShopifyProduct with variants, options and images
    save_shopify_product    


    # Create product with master variant.
    spree_product = Spree::Product.new(
                                  # id: id,
                                  name: title,
                                  description: body_html,
                                  slug: handle,
                                  available_on: published_at,
                                  price: default_variant.price,
                                  cost_price: default_variant.compare_at_price,
                                  weight: default_variant.grams,
                                  shipping_category: get_shipping_category,
                                  tax_category_id: get_tax_category_id(default_variant),
                                  # prototype_id: product_prototype_id,
                                  meta_title: get_meta_title,
                                  meta_description: get_meta_description,
                                  created_at: created_at,
                                  updated_at: updated_at                                  
      )

    if variants.size == 1
      # set master variant's sku
      spree_product.sku = default_variant.sku 
    end

    Rails.logger.debug "Creating Product: #{spree_product.name}(sku: #{spree_product.sku}), Shopify Product ID: #{self.id} "
    unless spree_product.save
      Rails.logger.debug "\n\n"
      Rails.logger.debug "#" * 80
      Rails.logger.debug "Could not save #{spree_product.class}: #{spree_product.inspect}"
      Rails.logger.debug "\n"
      Rails.logger.debug "Creating #{spree_product.class} Shopify Data:  #{self.inspect}"
      Rails.logger.debug "\n"
      Rails.logger.debug "Errors: #{spree_product.errors.full_messages}"
      Rails.logger.debug "\n"
      Rails.logger.debug "#" * 80
      raise "Could not save #{spree_product.class}, see log above \n\n"
    end

    # set inventory for master variant
    set_stock_quantity(spree_product.master, default_variant.inventory_quantity)

    if variants.size == 1
      ImportRef.create!(shopify_type: "Shopify::Variant", shopify_id: default_variant.id, spree_type: "Spree::Variant", spree_id: spree_product.master.id)
    end    

    self.imported_record = spree_product
    ImportRef.create!(shopify_type: self.class, shopify_id: id, spree_type: self.imported_record.class, spree_id: self.imported_record.id)

    # is master variant backorderable
    set_backorderable(spree_product.master, default_variant)
    

    # Assign category taxons to spree product from shopify's product_type
    set_category_taxons

    # Assign Tags as taxons
    set_tags_taxons

    # Assign Brand as taxons
    set_brand_taxons


    # # Create images
    set_images

    # Set Variants if exists
    set_variants

    self.imported_record = spree_product
    self
  end


  private

  def set_images
    if Shopify.config[:import_product_images] && images.present?
      threads = []
      images.sort_by{|i| i.position}.each do |shopify_image|
        threads << fork do
          image = Spree::Image.new(created_at: shopify_image.created_at, updated_at: shopify_image.updated_at)
          image.attachment = shopify_image.src 
          imported_record.master_images << image if image.save
        end
      end

      # Wait for all threads to join back
      threads.each { |thr| Process.waitpid(thr) }
    end
  end

  def set_brand_taxons
    if vendor.present?
      imported_record.taxons << get_brand_taxon
    end
  end

  def set_category_taxons
    category_taxon = get_category_taxon
    if category_taxon
      imported_record.taxons << category_taxon
    end
  end

  def set_tags_taxons
    if tags.present?
      imported_record.taxons << get_tag_taxons(tags)
    end
  end

  def get_option_type_name(option)
    if Shopify.config[:global_option_types]
      option.name
    else
      product_type.blank? ? option.name : "#{product_type}-#{option.name}"
    end
  end

  def build_variant(variant)
    sku = variant.sku
    count = Spree::Variant.where(sku: sku).count
    
    if count > 0
      if Shopify.config[:adjust_duplicate_sku] 
        sku = "#{sku}-#{variant.id}"
      else
        raise "Variant with sku: #{sku} already exists"
      end
    end


    spree_variant = imported_record.variants.build(
                      sku: sku,
                      weight: variant.grams,
                      price: variant.price,
                      cost_price: variant.compare_at_price,
                      tax_category_id: get_tax_category_id(variant),
                      track_inventory: variant.inventory_management == "shopify",
                      # is_master: (variant.position == 1),
                    )
  end

  def default_variant
    @default_variant ||= variants.first{|x| x.position == 1}
  end

  def get_tax_category_id(variant)
    variant.taxable? ? get_tax_category.id : nil
  end

  def get_brand_taxonomy
    @@brand_taxonomy ||= Spree::Taxonomy.find_or_create_by(name: 'Brand')
  end

  def get_shipping_category
    @@shipping_category ||= Spree::ShippingCategory.find_or_create_by(name: Shopify.config[:shipping_category])
  end

  def get_tax_category
    @@tax_category ||= Spree::TaxCategory.find_or_create_by(name: Shopify.config[:tax_category])
  end

  def get_brand_taxon
    if vendor.present?
      taxon = get_brand_taxonomy.taxons.find_or_create_by(name: vendor, parent_id: get_brand_taxonomy.root.id)
    end    
  end

  def get_category_taxonomy
    @@category_taxonomy ||= Spree::Taxonomy.find_or_create_by(name: 'Categories')
  end

  def get_category_taxon
    if product_type.present?
      taxon = get_category_taxonomy.taxons.find_or_create_by(name: product_type, parent_id: get_category_taxonomy.root.id)
    end    
  end

  def get_tag_taxons(tags)
    @@tag_taxonomy ||= Spree::Taxonomy.find_or_create_by(name: 'Tags')
    tags = tags.split(',') if tags.is_a? String
    tags.collect{|tag| @@tag_taxonomy.taxons.find_or_create_by(name: tag.strip, parent_id: @@tag_taxonomy.root.id)}
  end

  def get_stock_location
    @@stock_location ||= Spree::StockLocation.find_or_create_by(name: Shopify.config[:stock_location])
  end

  def get_meta_description
    desc_tag = get_metafields.find{|mf| mf.key == "description_tag"}
    desc_tag.nil? ? "" : desc_tag.value
  end

  def get_meta_title
    title_tag = get_metafields.find{|mf| mf.key == "title_tag"}
    title_tag.nil? ? "" : title_tag.value    
  end

  def get_metafields
    return {} unless Shopify.config[:import_metadata]
    @metafields ||= Shopify::Metafield.find(:all, :params => {:resource => self.class.collection_name, :resource_id => id})
  end

  def set_stock_quantity(variant, qty)
    return unless Shopify.config[:import_inventory]

    stock_location = get_stock_location
    Rails.logger.debug "Adding Stock QTY: #{variant.sku}: #{qty}"
    stock_movement = stock_location.stock_movements.build(quantity: qty)
    stock_movement.stock_item = stock_location.set_up_stock_item(variant)
    stock_movement.save!    
  end

  def set_backorderable(spree_variant, shopify_variant)
    inventory_policy = shopify_variant.inventory_policy rescue ""
    spree_variant.stock_items.each do |si|
      si.update_attribute(:backorderable, inventory_policy == "continue")
    end
  end


  def set_variants
    if variants.size > 1
      
      # Create option type option values
      set_option_type_option_values

      # create variants
      variants.each do |variant|
        spree_variant = build_variant(variant)
        
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

        Rails.logger.debug "Adding Variant: #{variant.sku}"
        spree_variant.save!
        ImportRef.create!(shopify_type: "Shopify::Variant", shopify_id: variant.id, spree_type: "Spree::Variant", spree_id: spree_variant.id)
        
        # set inventory
        set_stock_quantity(spree_variant, variant.inventory_quantity)


        # set if the variant is backorderable
         set_backorderable(spree_variant, variant)
      end
    end

  end

  def set_option_type_option_values
    options.each do |option|
      option_type_name =  get_option_type_name(option)
      spree_option_type = Spree::OptionType.find_by(name: option_type_name)

      if spree_option_type.nil?
        spree_option_type = Spree::OptionType.create!(name: option_type_name, presentation: option.name)
      end
      
      option.values.each do |ov|
        spree_option_type.option_values.find_or_create_by(name: ov, presentation: ov)
      end

      imported_record.option_types << spree_option_type
    end
  end    

  def save_shopify_product
    product = self 
    
    ShopifyProduct.transaction do 
      sp = ShopifyProduct.new

      ShopifyProduct::ATTRIBUTES.each do |attr|
        sp.public_send("#{attr}=", product.public_send(attr))
      end
      sp.save!

      variants.each do |variant|
        sv = sp.shopify_variants.build
        
        ShopifyVariant::ATTRIBUTES.each do |attr|
          sv.public_send("#{attr}=", variant.public_send(attr))
        end
        sv.save!
      end

      options.each do |option|
        so = sp.shopify_options.build
        
        ShopifyOption::ATTRIBUTES.each do |attr|
          so.public_send("#{attr}=", option.public_send(attr))
        end
        so.save!
      end

      images.each do |image|
        si = sp.shopify_images.build
        
        ShopifyImage::ATTRIBUTES.each do |attr|
          si.public_send("#{attr}=", image.public_send(attr))
        end
        si.save!
      end

    end
  end

  # def product_prototype_id
  #   if product_type.present?
  #     prototype = Spree::Prototype.find_or_create_by(name: product_type)
  #     prototype.id
  #   end
  # end

  
end