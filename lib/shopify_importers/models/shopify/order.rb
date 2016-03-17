class Shopify::Order < Shopify::Importer
  self.collection_name = "orders"

  attr_accessor :imported_record

  def import 
    # Spree Order object
    spree_order = Spree::Order.new(
                                    # additional_tax_total: '',
                                    # adjustment_total: '',
                                    # approved_at: '',
                                    # approver_id: '',
                                    # bill_address_id: '',
                                    # confirmation_delivered: '',
                                    # considered_risky: '',
                                    # currency: '',
                                    # included_tax_total: '',
                                    # item_count: '',
                                    # item_total: '',
                                    # payment_state: '',
                                    # payment_total: '',
                                    # promo_total: '',
                                    # ship_address_id: '',
                                    # shipment_state: '',
                                    # shipment_total: '',
                                    # shipping_method_id: '',
                                    # special_instructions: '',
                                    # state: '',
                                    # state_lock_version: '',
                                    # store_id: '',
                                    # total: '',
                                    # canceler_id: '',
                                    channel: 'Shopify',
                                    email: email,
                                    guest_token: cart_token,
                                    last_ip_address: browser_ip,
                                    number: get_order_number,
                                    user_id: get_spree_user(email).try(:id),
                                    created_by_id: '',
                                    created_at: created_at,
                                    updated_at: updated_at,
                                    completed_at: processed_at,
                                    canceled_at: cancelled_at,


      )

    unless spree_order.save
      Rails.logger.debug "\n\n"
      Rails.logger.debug "#" * 80
      Rails.logger.debug "Could not save Spree::Order: #{spree_order.inspect}"
      Rails.logger.debug "\n"
      Rails.logger.debug "Creating Spree::Order Shopify Data:  #{self.inspect}"
      Rails.logger.debug "\n"
      Rails.logger.debug "Errors: #{spree_order.errors.full_messages}"
      Rails.logger.debug "\n"
      Rails.logger.debug "#" * 80
      raise "Could not save Spree::Order, see log above \n\n"
    end

    self.imported_record = spree_order
    ImportRef.create!(shopify_type: self.class, shopify_id: id, spree_type: self.imported_record.class, spree_id: self.imported_record.id)

    # assign Lineitems
    set_line_items    

    spree_order.update!
    self
  end


  private

  def get_payment_state

    shopify_payment_states = %w(pending authorized partially_paid paid partially_refunded refunded voided)
    spree_payment_states = %w(balance_due checkout completed credit_owed failed paid pending processing void)
  end

  def get_order_number
    Shopify.config[:order_number_prefix] + order_number.to_s
  end

  def set_line_items
    line_items.each do |shopify_li|
      spree_variant_id = ImportRef.where(shopify_type: "Shopify::Variant", shopify_id: shopify_li.variant_id).first.spree_id
      variant = Spree::Variant.find_by(id: spree_variant_id)
      li = imported_record.line_items.create!(
                                            variant_id: spree_variant_id, 
                                            quantity: shopify_li.quantity,
                                            price: shopify_li.price,


                                        )

    ImportRef.create!(shopify_type: "Shopify::LineItem", shopify_id: shopify_li.id, spree_type: "Spree::LineItem", spree_id: li.id)
    end 
  end

  def get_spree_user(email)
    @order_user ||= Spree.user_class.find_by(email: email)
  end

  # def get_random_password
  #   @random_password ||= SecureRandom.hex(8)
  # end

end

